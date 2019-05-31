#!/bin/sh
# test latency from common public DNS servers, and include any IP Addresses from STDIN

get_latency() {
# receive IP address as request and return latency in ms from system host call
	local this_dns_server=$1
	local this_result=$(host -W 1 -v google.com $this_dns_server|grep Received|awk {'print $7'})
	echo $this_result
}


get_latency_avg() {
# receive integers, count them, sum them, and divdie by count
	local this_req_count=$(echo $@|wc -w)
	# doing nothing scales well
	if [ "$this_req_count" -lt "2" ]; then
		exit
	fi
	# line up for calculator
	local this_req_sum=$(echo $@|tr " " "+"|bc -l)
	# the monster math, it was a graveyard graph
	local this_res=$(echo $this_req_sum / $this_req_count|bc)
	echo $this_res
}


main() {
# flow control and orchestration	
	# iterate through dns server list
	for this_dns_server in $dns_servers; do
		# get latency
		this_result=$(get_latency $this_dns_server)
		# average latency
		this_latency_avg=$(get_latency_avg $this_result)
		# doing nothing scales well
		if [ "$this_latency_avg" ]; then
			echo $this_latency_avg $this_dns_server
		fi
	done|
		# decending numberic sort on latency value
		sort -n|
		# paint product
		awk {'print ""$2" has an average latency of "$1" milliseconds"'}
}


# common public dns servers
dns_servers="
	209.244.0.3 209.244.0.4
	64.6.64.6 64.6.65.6
	8.8.4.4 8.8.8.8
	9.9.9.9 149.112.112.112
	208.67.222.222 208.67.220.220
	216.146.35.35 216.146.36.36
	37.235.1.174 37.235.1.177
";


# work with stdin
while read -t 1 line; do
	# add consumer supplied data from STDIN to public dns server list
	dns_servers+=$(echo $line|
		grep -v [A-z]|
		grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
done


main
