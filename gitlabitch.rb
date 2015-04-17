#!/usr/bin/env ruby

require 'grape'
require 'git'
require 'etc'
require 'json'
require 'yaml'
require 'syslog/logger'

$0 = 'gitlabitch [...]'

begin 
  $config = YAML::load( File.open  '/etc/gitlabitch.yaml' )
rescue
  puts "Can't read config file"
  exit 1
end

$0 = 'gitlabitch ' + $config["projects"].keys.to_json.gsub(/\"/,'')


module GitLaBitch
  
  class Server < Grape::API

    version 1, using: :header, vendor: 'blufor'
    format :json

    $config["projects"].keys.each do |project|

      resource "/#{project}" do
        desc "GitLaBitch #{project} Webhook"

        logger Syslog::Logger.new('gitlabitch')

        helpers do
          def logger
            Server.logger
          end
        end

        post do
          logger.info "Request for #{project} from #{env['REMOTE_ADDR']}"
          base_dir = $config["projects"][project]["basedir"] + "/"
          user = $config["projects"][project]["user"]
          serviced_branches = $config["projects"][project]["branches"]        
          old = params[:before]
          new = params[:after]
          ref = params[:ref]
          repo = nil
          repo_url = params[:repository][:url]
          repo_name = params[:repository][:url]
          commit_url = params[:commits].first[:url]
          commit_user = params[:user_name]
          message = params[:commits].first[:message]
          branch = ref.split('/')[2]

          if serviced_branches.kind_of? Array
            multibranch = true
          else
            multibranch = false
            serviced_branches = [ serviced_branches ]
          end

          if serviced_branches.include? branch
            if multibranch == true
              branch_dir = nil
              if branch == "master" && $config["projects"][project]["master_name"]
                branch_dir = $config["projects"][project]["master_name"]
              end
              branch_dir ||= branch
            else
              branch_dir = ''
            end

            logger.info "#{project}: Forking process"

            Process.fork do
              # setuid to configured user (uses his ssh key and fs perms!)
              Process.uid = Etc.getpwnam(user).uid
              logger.info "#{project}: SetUID of child process to #{user}(#{Process.uid})"
              # if the branch isn't mirrored yet, create it
              if ! File.directory?(base_dir + branch_dir) then
                logger.info "#{project}: Creating nonexisting mirror in #{base_dir+branch_dir}"
                repo = Git.init(base_dir + branch_dir)
                repo.add_remote branch, repo_url, :track => branch
                repo.remote(branch).fetch
              else
                logger.info "#{project}: Opening existing mirror in #{base_dir+branch_dir}"
                repo = Git.open(base_dir + branch_dir)
              end
              logger.info "#{project}: Syncing #{repo_url} branch #{branch}"
              if repo.pull branch, branch            
                logger.info "#{project}: Synced"
              else
                logger.info "#{project}: Already in sync"
              end
            end
            Process.wait
            logger.info "#{project}: Child finished"
          else
            logger.info "#{project}: Branch #{branch} not mirrorred"
            error! "No Content", 204
          end
        end
      end
    end
  end
end

