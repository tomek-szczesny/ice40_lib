none:
	g++ -Ofast prcnt.cpp -o prcnt
	g++ -Ofast prdiv.cpp -o prdiv

generate_cntrs:
	seq 6 10 | xargs -I _ ./prcnt _ 2 | sed "/^\/\/\/\/.*/d" | tee counters_pr.v

generate_divs:
	seq 6 10 | xargs -I _ ./prdiv _ 2 | sed "/^\/\/\/\/.*/d" | tee divs_pr.v
