# solr-performance

Measuring Solr REST API performance, using Cloudera Public Cloud.

## Setup test environment

### Step 1: create test cluster

Create a Data Hub, using the template called "Data exploration and analytics".


### Step 2: create test collection and add dummy data

The following command can be executed on e.g. on any worker node of the data hub cluster. 
For more info about using solrctl and authenticating on secure clusters, see: 
https://docs.cloudera.com/cdp-private-cloud-base/7.1.7/search-solrctl-reference/topics/search-solrctl-ref.html?

```
solrctl instancedir --generate books
solrctl instancedir --create books books
solrctl collection --create books -s 3 -r 1

curl -k --negotiate -u : 'https://<hostname of any Solr worker>:8985/solr/books/update?commit=true'  -H 'Content-type:application/json' -d '
[
  {"id" : "book1",   "title" : "Saci The Solr expert",   "author" : "Istvan Farkas"},
  {"id" : "book2",   "title" : "Vasarosdombo Tortenete",   "author" : "Janos Kovacs"},
  {"id" : "book3",   "title" : "The C Programming language",   "author" : "Brian Kernighan, Dennis Ritchie"},
  {"id" : "book4",   "title" : "Assembly Language for X86 Processors",   "author" : "Kip R. Irvine"},
  {"id" : "book5",   "title" : "Physics 1",   "author" : "Laszlo Holics"},
  {"id" : "book6",   "title" : "Pannonia Motorcycles",   "author" : "Zoltan Ocskay"},
  {"id" : "book7",   "title" : "Physics 2",   "author" : "Laszlo Holics"},
  {"id" : "book8",   "title" : "Test book 1",   "author" : "Test Author 1"},
  {"id" : "book9",   "title" : "Pruning fruit trees",   "author" : "Dr. Bela Zoltan Sipos"},
  {"id" : "book10",   "title" : "Winnetou",   "author" : "Karl May"},
  {"id" : "book11",   "title" : "Refactoring",   "author" : "Martin Fowler"},
  {"id" : "book12",   "title" : "Back to the future",   "author" : "Doc Brown"}
]' 
```

### Step 3: test queries to reach Solr

To reach the Solr API directly, try:
```
curl -k --negotiate -u : 'https://<hostname of any Solr worker>:8985/solr/books/select?q=*:*'
```


To reach the Solr API through Knox, try:
```
curl -ik --user "workload_user:workload_password" 'https://<hostname of Knox Gateway>/solr-cluster/cdp-proxy-api/solr/books/select?q=*:*'
```


## Running the benchmark script

The example below shows the running of the benchmark script, using 4 threads and running 25 queries on each thread. 
(of course, you need to specify real configuration to the environment variables KNOX_AUTH, SOLR_WORKER_HOST and KNOX_HOST to make the script to run)
 
``` 
export KNOX_AUTH='my_workload_user:my_workload_password'
export SOLR_WORKER_HOST='<hostname of any Solr worker>'
export KNOX_HOST='<hostname of Knox Gateway>'
export KNOX_COOKIE_PATH=./cookies.knox.txt
export SOLR_COOKIE_PATH=./cookies.solr.txt
 
 
./run_banchmark.sh 4 25

 
================================================
executing Solr queries directly, without knox:
================================================
 
 
using file to store cookies: ./cookies.solr.txt
using command:
curl -k --negotiate -u : https://<hostname of any Solr worker>:8985/solr/books/select?q=*:* --cookie-jar ./cookies.solr.txt --cookie ./cookies.solr.txt
 
starting thread 1/4, executing 25 Solr operations
starting thread 2/4, executing 25 Solr operations
starting thread 3/4, executing 25 Solr operations
starting thread 4/4, executing 25 Solr operations
 
Run time: 4046 ms
Number of threads: 4
Number of operations per thread: 25
Total number of operations: 100
Average response time: 161 ms
Throughput: 25 ops/sec
 
 
================================================
executing Solr queries using knox:
================================================
 
 
using file to store cookies: ./cookies.knox.txt
using command:
curl -ik --user my_workload_user:my_workload_password https://<hostname of Knox Gateway>/solr-cluster/cdp-proxy-api/solr/books/select?q=*:* --cookie-jar ./cookies.knox.txt --cookie ./cookies.knox.txt
 
starting thread 1/4, executing 25 Solr operations
starting thread 2/4, executing 25 Solr operations
starting thread 3/4, executing 25 Solr operations
starting thread 4/4, executing 25 Solr operations
 
Run time: 4663 ms
Number of threads: 4
Number of operations per thread: 25
Total number of operations: 100
Average response time: 186 ms
Throughput: 25 ops/sec
```

## License

Source code in this repository is under Apache 2.0 license.
