#!/bin/bash
apiHost="localhost"
statsdHost="localhost"
statsdPort="8125"  # Replace with your StatsD port
timestamp=$(date +%s)
response=$(curl -s "$apiHost:8888/v1/chain/get_info")

if [ $? -eq 0 ]; then
  head_block_time=$(curl -s "$apiHost:8888/v1/chain/get_info" | jq -r .head_block_time)
  head_block_num=$(curl -s "$apiHost:8888/v1/chain/get_info" | jq -r .head_block_num)
  head_block_timestamp=$(date -d "$head_block_time" +%s)
  difference_in_time=$(bc <<< "$timestamp - $head_block_timestamp")
  head_block_num_global=$(bc <<< "$difference_in_time * 2")
else
  head_block_time=0
  head_block_num=0
  difference_in_time=0
  head_block_num_global=0
fi

# Send metrics to StatsD
echo "head_block_num:$head_block_num|g" | nc -u -w0 "$statsdHost" "$statsdPort"
echo "head_block_num_global:$head_block_num_global|g" | nc -u -w0 "$statsdHost" "$statsdPort"
echo "head_block_time:$head_block_timestamp|g" | nc -u -w0 "$statsdHost" "$statsdPort"
echo "head_block_time_difference:$difference_in_time|g" | nc -u -w0 "$statsdHost" "$statsdPort"
