# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'rubygems'
require 'bundler/setup'
require 'json'

require 'myst'

include Myst::Providers::VCloud

def update_instance(data)
  credentials = data[:datacenter_username].split('@')
  provider = Provider.new(endpoint:     data[:vcloud_url],
                          organisation: credentials.last,
                          username:     credentials.first,
                          password:     data[:datacenter_password])
  datacenter  = provider.datacenter(data[:datacenter_name])
  instance    = datacenter.compute_instance(data[:name])
  instance.tasks.each { |task| task.waitForTask(0, 1000) }

  instance.power_off if instance.vapp.isDeployed

  instance.hostname = data[:hostname]
  instance.cpus = data[:cpus]
  instance.memory  = data[:ram]

  if instance.nics.count == 0
    network_interace = NetworkInterface.new(client:     client,
                                            id:         0,
                                            network:    data[:network_name],
                                            ipaddress:  data[:ip],
                                            primary:    true)
    instance.add_nic(network_interace)
  end
  instance.tasks.each { |task| task.waitForTask(0, 1000) }

  if data[:disks]
    existing_disks = instance.disks.select(&:isHardDisk)

    data[:disks].each do |disk|
      if existing_disks[disk[:id]].nil?
        dsk = AttachedStorage.new(client: client, id: disk[:id], size: disk[:size])
        instance.add_disk(dsk)
      elsif existing_disks[disk[:id]].getHardDiskSize < disk[:size]
        existing_disks[disk[:id]].updateHardDiskSize(disk[:size])
        instance.vm.updateDisks(instance.vm.getDisks).waitForTask(0, 1000)
      end
    end
  end

  instance.tasks.each { |task| task.waitForTask(0, 1000) }
  instance.power_on

  'instance.update.vcloud.done'
rescue => e
  puts e
  puts e.backtrace
  'instance.update.vcloud.error'
end

unless defined? @@test
  @data       = { id: SecureRandom.uuid, type: ARGV[0] }
  @data.merge! JSON.parse(ARGV[1], symbolize_names: true)

  original_stdout = $stdout
  $stdout = StringIO.new
  begin
    @data[:type] = update_instance(@data)
    if @data[:type].include? 'error'
      @data['error'] = { code: 0, message: $stdout.string.to_s }
    end
  ensure
    $stdout = original_stdout
  end
  puts @data.to_json
end
