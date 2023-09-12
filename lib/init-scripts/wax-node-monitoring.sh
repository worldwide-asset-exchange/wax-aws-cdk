#!/bin/bash
apiHost="localhost"
timestamp=`date +%s`
response=$(curl -s $apiHost:8888/v1/chain/get_info)
if [ $? -eq 0 ]; then
  head_block_time=`curl -s $apiHost:8888/v1/chain/get_info | jq -r .head_block_time`
  head_block_num=`curl -s $apiHost:8888/v1/chain/get_info | jq -r .head_block_num`
  head_block_timestamp=`date -d "$head_block_time" +%s`
  difference_in_time=`bc <<< "$timestamp - $head_block_timestamp"`
else
  head_block_time=0
  head_block_num=0
  difference_in_time=0
fi
echo "head_block_num value=$head_block_num $timestamp"
echo "head_block_time value=$head_block_timestamp $timestamp"
echo "head_block_time_difference value=$difference_in_time $timestamp"
