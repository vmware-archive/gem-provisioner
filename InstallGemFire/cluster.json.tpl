{
    "global-properties":{
        "gemfire": "/runtime/gemfire",
        "java-home" : "/runtime/java",
        "locators" : "10.0.0.{{ Servers[ServerNum].Installations[InstallationNum].LocatorServerNumber }}[10000]",
        "cluster-home" : "/runtime/cluster"
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
        "jvm-options" : ["-Xmx{{ Servers[ServerNum].Installations[InstallationNum].Memory }}","-Xms{{ Servers[ServerNum].Installations[InstallationNum].Memory }}", "-XX:+UseConcMarkSweepGC", "-XX:+UseParNewGC"]
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
        "jvm-options" : ["-Xmx{{ Servers[ServerNum].Installations[InstallationNum].Memory }}","-Xms{{ Servers[ServerNum].Installations[InstallationNum].Memory }}","-Xmn1g", "-XX:+UseConcMarkSweepGC", "-XX:+UseParNewGC", "-XX:CMSInitiatingOccupancyFraction=75"]
    },
    "hosts": {
    {% for Server in Servers %}
    {% for Installation in Server.Installations %}
    {% if Installation.Name == "InstallGemFire" %}
        "ip-10-0-0-{{ Server.ServerNumber }}" : {
            "host-properties" :  {
             },
             "processes" : {
                {% if Installation.Role == "locator" %}
                "locator" : {
                    "type" : "locator",
                    "bind-address": "10.0.0.{{ Server.ServerNumber }}",
                    "http-service-bind-address" : "10.0.0.{{ Server.ServerNumber }}",
                    "jmx-manager-bind-address" : "10.0.0.{{ Server.ServerNumber }}"
                 }
                {% endif %}
                {% if Installation.Role == "datanode" %}
                "server" : {
                    "type" : "datanode",
                    "bind-address": "10.0.0.{{ Server.ServerNumber }}",
                    "server-bind-address" : "10.0.0.{{ Server.ServerNumber }}"
                 }
                {% endif %}
             }
        },
    {% endif %}
    {% endfor %}
    {% endfor %}
        "dummy": "this is just here to make the json correct"
   }
}

