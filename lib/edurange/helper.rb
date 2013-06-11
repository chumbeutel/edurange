module Edurange
  class Helper
    def self.startup_script
      File.open('my-user-script.sh', 'rb').read
    end
    # Creates Bash lines to create user account and set password file or password given users
    #
    # ==== Attributes
    #
    # * +users+ - Takes parsed users
    # 
    def self.users_to_bash(users)
      puts "Got users in users to bash:"
      p users
      shell = ""
      users.each do |user|
        if user['password']
          shell += "\n"
          shell += "sudo useradd -m #{user['login']} -s /bin/bash\n"
          # Regex for alphanum only in password input
          shell += "echo #{user['login']}:#{user['password'].gsub(/[^a-zA-Z0-9]/, "")} | chpasswd\n" 
      # TODO - do something
        elsif user['pass_file']
          name = user['login']
          stuff = <<stuff
          
# Adds a user, checks their password, and makes a directory
useradd -m #{name} -g admin -s /bin/bash
echo "#{name}:password" | chpasswd
mkdir -p /home/#{name}/.ssh

key='#{user['pass_file'].chomp}'
gen_pub='#{user["generated_pub"]}'
gen_priv='#{user["generated_priv"]}'

# Checks their keys
echo $gen_pub >> /home/#{name}/.ssh/authorized_keys
echo $gen_priv >> /home/#{name}/.ssh/id_rsa
echo $gen_pub >> /home/#{name}/.ssh/id_rsa.pub
chmod 600 /home/#{name}/.ssh/id_rsa
chmod 600 /home/#{name}/.ssh/authorized_keys
chmod 600 /home/#{name}/.ssh/id_rsa.pub
chown -R #{name} /home/#{name}/.ssh
stuff
          shell += stuff
        end
      end
      shell
    end
    def self.prep_nat_instance(players)
      # get nat instance ready
      data = <<data
#!/bin/sh
set -e
set -x
echo "Hello World.  The time is now $(date -R)!" | tee /root/output.txt
curl http://ccdc.boesen.me/edurange.txt > /etc/motd
data
  players.each do |player|
    `rm id_rsa id_rsa.pub`
    `ssh-keygen -t rsa -f id_rsa -q -N ''`
    priv_key = File.open('id_rsa', 'rb').read
    pub_key = File.open('id_rsa.pub', 'rb').read

    player["generated_pub"] = pub_key
    player["generated_priv"] = pub_key

    data += <<data
adduser -m #{player["login"]}
mkdir -p /home/#{player["login"]}/.ssh
echo '#{player["pass_file"]}' >> /home/#{player["login"]}/.ssh/authorized_keys
echo '#{priv_key}' >> /home/#{player["login"]}/.ssh/id_rsa
echo '#{pub_key}' >> /home/#{player["login"]}/.ssh/id_rsa.pub
chmod 600 /home/#{player["login"]}/.ssh/id_rsa
chmod 600 /home/#{player["login"]}/.ssh/authorized_keys
chmod 600 /home/#{player["login"]}/.ssh/id_rsa.pub
chown -R #{player["login"]} /home/#{player["login"]}/.ssh
data
      end
      data
    end

  end
end

