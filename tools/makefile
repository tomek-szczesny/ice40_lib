none:
	g++ -Ofast prcnt.cpp -o prcnt

generate:
	seq 6 10 | xargs -I _ ./prcnt _ 2 | sed "/^\/\/\/\/.*/d" | tee counters_pr.v
