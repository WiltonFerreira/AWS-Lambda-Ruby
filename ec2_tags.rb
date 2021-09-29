require 'aws-sdk-ec2'

region = 'us-west-2'
minhakey = 'True'
minhatag = 'ScheduledStartStop'

@my_instances=[]

#Metodo para iniciar a instancia
def instance_started?(ec2_client, instance_id)
    response = ec2_client.describe_instance_status(instance_ids: [instance_id])
  
    if response.instance_statuses.count.positive?
        state = response.instance_statuses[0].instance_state.name
        case state
        when 'pending'
            puts 'Error starting instance: the instance is pending. Try again later.'
            return false
        when 'running'
            puts 'The instance is already running.'
            return true
        when 'terminated'
            puts 'Error starting instance: ' \
            'the instance is terminated, so you cannot start it.'
            return false
        end
    end
  
    ec2_client.start_instances(instance_ids: [instance_id])
    ec2_client.wait_until(:instance_running, instance_ids: [instance_id])
        puts 'Instance started.'
    return true
  
    rescue StandardError => e
        puts "Error starting instance: #{e.message}"
    return false
end


def instance_stopped?(ec2_client, instance_id)
    response = ec2_client.describe_instance_status(instance_ids: [instance_id])
  
    if response.instance_statuses.count.positive?
        state = response.instance_statuses[0].instance_state.name
        case state
            when 'stopping'
                puts 'The instance is already stopping.'
                return true
            when 'stopped'
                puts 'The instance is already stopped.'
                return true
            when 'terminated'
                puts 'Error stopping instance: ' \
                'the instance is terminated, so you cannot stop it.'
                return false
        end
    end
  
    ec2_client.stop_instances(instance_ids: [instance_id])
    ec2_client.wait_until(:instance_stopped, instance_ids: [instance_id])
    puts 'Instance stopped.'
    return true
  
    rescue StandardError => e
        puts "Error stopping instance: #{e.message}"
        return false
end

def lista_instancekeys(ec2_resource,minhatag,minhakey)
    response = ec2_resource.instances(
        filters: [
            {
                name: "tag:#{minhatag}",
                values: [minhakey]
            }
        ]
    )

    if response.count.positive?
        puts 'Instance: ID, STATE, tag KEY/VALUE'
        response.each do |instance|
            print "#{instance.id}, #{instance.state.name}"
            instance.tags.each do |tag|
                print ", #{tag.key}/#{tag.value}"
                @my_instances.push(instance.id)
            end
            print "\n"
        end
    end
    rescue StandardError => e
    puts "Error getting information about instances: #{e.message}"

end

###

client= Aws::EC2::Client.new(region: region)
resource = Aws::EC2::Resource.new(region: region)

puts "\r\n"
puts 'LISTAS DAS INSTANCIAS COM TAG PARA DESLIGAMENTO'
puts '-' *47
lista_instancekeys(resource,minhatag,minhakey)
puts '-' *19
puts "\r\n"

#LISTA DAS INSTANCIAS
#puts @my_instances.uniq

#unless instance_stopped?(client, instance_id)
#    puts 'Could not stop instance.'
#end

#unless instance_started?(client, instance_id)
#    puts 'Could not start instance.'
#end