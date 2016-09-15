{
    "global-properties":{
        "gemfire": "/runtime/gemfire",
        "java-home" : "/runtime/java",
        "locators" : "192.168.1.101[10000]",
        "cluster-home" : "/runtime/gem_cluster_1"
    },
   "locator-properties" : {
        "port" : 10000,
        "jmx-manager-port" : 11099,
        "http-service-port" : 17070,
        "jmx-manager" : "true",
        "jmx-manager-start" : "true",
        "log-level" : "config",
        "statistic-sampling-enabled" : "true",
        "statistic-archive-file" : "locator.gfs",
        "log-file-size-limit" : "10",
        "log-disk-space-limit" : "100",
        "archive-file-size-limit" : "10",
        "archive-disk-space-limit" : "100",
        "jvm-options" : ["-Xmx8g","-Xms8g", "-XX:+UseConcMarkSweepGC", "-XX:+UseParNewGC"]
    },
   "datanode-properties" : {
        "server-port" : 10100,
        "conserve-sockets" : false,
        "log-level" : "config",
        "statistic-sampling-enabled" : "true",
        "statistic-archive-file" : "datanode.gfs",
        "log-file-size-limit" : "10",
        "log-disk-space-limit" : "100",
        "archive-file-size-limit" : "10",
        "archive-disk-space-limit" : "100",
        "jvm-options" : ["-Xmx12g","-Xms12g","-Xmn2g", "-XX:+UseConcMarkSweepGC", "-XX:+UseParNewGC", "-XX:CMSInitiatingOccupancyFraction=75"]
    },
    "hosts": {
    {% set firstOne = true %}
    {% for Server in Servers  %}
    {% for Installation in Server.Installations if Installation.Name == 'InstallGemFireCluster' %}
        "ip-192-168-1-{{ Server.ServerNumber }}" : {
            "host-properties" :  {
             },
             "processes" : {
                {% if Server.ServerNumber == 101 %}
                "locator" : {
                    "type" : "locator",
                    "bind-address": "192.168.1.{{ Server.ServerNumber }}",
                    "http-service-bind-address" : "192.168.1.{{ Server.ServerNumber }}",
                    "jmx-manager-bind-address" : "192.168.1.{{ Server.ServerNumber }}",
                    "jmx-manager-hostname-for-clients" : "{{ Server.PublicIpAddress }}"
                 }
                {% else %}
                "server{{ Server.ServerNumber }}" : {
                    "type" : "datanode",
                    "bind-address": "192.168.1.{{ Server.ServerNumber }}",
                    "server-bind-address" : "192.168.1.{{ Server.ServerNumber }}",
                    "hostname-for-clients" : "{{ Server.PublicIpAddress }}"
                 }
                {% endif %}
             },
             "ssh" : {
                "host" : "{{ Server.PublicIpAddress }}",
                "user" : "{{ Server.SSHUser }}",
                "key-file" : "{{ SSHKeyPath }}"
             }
        },
    {% endfor %}
    {% endfor %}
        "dummy" : {
            "processes": []
        }
   }
}

