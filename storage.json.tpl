{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Resources": {
    {#########EBS Volumes ##############}
    {% for Server in Servers %}
    {% for Device in Server.BlockDevices if Device.DeviceType == 'EBS' %}
    "EBSVol{{ Server.Name }}{{ loop.index }}" : {
      "Type":"AWS::EC2::Volume",
      "Properties" : {
        "AvailabilityZone" : "{{ AvailabilityZone }}",
        "Size" : {{ Device.Size }},
        "VolumeType" : "{{ Device.EBSVolumeType }}",
        "Tags" : [
          {
            "Key":"Name",
            "Value" : "{{ EnvironmentName }}-EBSVol-{{ Server.Name }}-{{ loop.index }}"
          },
          {####
            The tags below are used to map an EBS volume to its intended server.
            Do not change them.
          ####}
          {
            "Key":"Environment",
            "Value" : "{{ EnvironmentName }}"
          },
          {
            "Key":"ServerName",
            "Value" : "{{ Server.Name }}"
          },
          {
            "Key":"Device",
            "Value" : "{{ Device.Device }}"
          }
        ]
      }    
    }
    {% if not loop.last %}, {% endif %}
    {% endfor %}
    {% if not loop.last %}, {% endif %}
    {% endfor %}
  },
  "Description": "{{ EnvironmentName }} Storage Stack"
}