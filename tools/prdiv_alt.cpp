// Pseudo random divider 
// LUT configuration finder
// and Verilog module generator
// by Tomek Szczęsny 2024
//
// This code is a mess.
// Do not attempt to understand any of that.
//

#include <bitset>
#include <chrono>
#include <cmath>
#include <future>
#include <iostream>
#include <stdlib.h>     /* srand, rand */
#include <string>
#include <thread>
#include <time.h>	// For srand
#include <vector>
	
int p = 0;		// Counter period  (cmd line arg)
int b = 0;		// Counter bitness (based on p)
int sx = 3;		// Max extra bits  (cmd line arg)
int x = 0;		// Extra bits
		
int max = std::pow(2,16)-1;

int fact(int in)
{
	int o = 1;
	int i;
	for (i=2;i<=in;i++)
	{
		o *= i;
	}
	return o;
}

class lut {
	// A class representing a 4-bit LUT
	// It supports "don't care" states to some extent
	
	private:
		int lut_d = 0;
		int lut_x = max;
	
	public:
	lut()
	{
		lut_d = 0;
		lut_x = max;
	}
	// reading
	bool operator[](int i) const
	{
		return ((lut_d >> i) & 1);
	}
	//writing
	// Returns zero when trying to overwrite an opposite value
	bool set (int i, bool val)
	{
		int p = 1 << i;
		if (bool(lut_d & p) != val)
		{
			if (!(lut_x & p)) return 0;
			if (val) lut_d |= p;
		}
		if (lut_x & p) lut_x -= p; // lut_x &= !p;
		return 1;
	}
	void unset (int i)
	{
		int p = 1 < i;
		lut_d &= !p;
		lut_x |= p;
	}
	void clear()
	{
		lut_d = 0;
		lut_x = max;
	}

	std::string str()
	{
		int i;
		std::string ret;
		for (i=15;i>=0;i--)
		{
			if ((lut_x >> i) & 1) ret += "x";
			else ret += (((lut_d >> i ) & 1) ? "1" : "0");
		}
		return ret;
	}
	// Evaluates the LUT output for a given set of inputs,
	// represented by a binary number 0000 - 1111.
	bool eval(int d)
	{
		return ((lut_d >> d) & 1);
	}
};

std::vector<lut> empty_luts;

class comb {
	// A class representing a combination "k of n"
	// without repetitions
	// Used for selecting LUT inputs
	// It can also return "k of n" bits from an integer.

	private:
		char c = 0;
		char k = 0;
		char n = 0;

	public:

	comb(int k, int n)
	{
		this->k = k;
		this->n = n;
		//c = int(std::pow(2,k)-1) << (n-k);	// The first combination
		//c = 0;
	}
	// Set the next combination
	// Returns zero if rolled over.
	bool next()
	{
		int i;
		while (1)
		{
			this->c++;
			this->c &= int(pow(2,n)-1);
			if (c == 0) 
			{
				this->next();
				return 0;
			}
			if (this->check()) return 1;
		}
	}
	// Set an internal state
	// If the state is invalid, it tries to reach the next valid one.
	// Returns zero if rolled over in the process.
	bool set(int i)
	{
		c = i;
		if (this->check()) return 1;
		else return this->next();
	}
	// Checks if its internal state is valid.
	// Mostly for internal use.
	bool check()
	{
		int i;
		int o = 0;
		for (i=0; i<n; i++)
		{
			o += (c >> i) & 1;
		}
		return (o == k);
	}
	// Composes a new int from selected bits of the in.
	inline int map(int in)
	{
		int ret = 0;
		char i = 0;
		char k = 0;
		int cc = c;
		while (cc != 0) //i<n)
		{
			if (cc & 1) 
			{
				ret |= (in & 1) << i-k;
			}
			else k++;
			cc = cc >> 1;
			in = in >> 1;
			i++;
		}
		return ret;
	}
	// get current state as a string
	std::string str()
	{
		int i;
		std::string ret;
		for (i=n-1;i>=0;i--)
		{
			ret += ((c >> i) & 1 ? "1" : "0");
		}
		return ret;
	}
	// get current state as a vector of numbers
	std::vector<int> vec()
	{
		int i;
		std::vector<int> ret;
		for (i=0;i<n;i++)
		{
			if ((c >> i) & 1) ret.push_back(i);
		}
		return ret;
	}
	int intg()
	{
		return c;
	}


};

class vari {
	// Helps generating variants without repetitions
	// Operates on a range of numbers from l to h.
	// selects k of n items, where n = (h-l+1);
	
	private:
	int k; int n;
	std::vector<int> s;		// internal state
	std::vector<int> range;
	std::vector<int> result;
	
	// Generates the next internal state.
	bool next_state(int num = 1000)
	{
		int i;
		if (num > k-1) num = k-1;
		s[num] +=1;
		for (i=num; i>=0; i--)
		{
			if (s[i] > n-i-1)
			{
				s[i] = 0;
				if (i == 0) return 0;
				s[i-1] += 1;
			}
		}
		for (i=num+1; i<k; i++)
		{
			s[i] = 0;
		}
		return 1;
	}

	public:
		
	vari(int l, int h, int k)
	{
		int i;
		this->n = h-l+1;
		this->k = k;
		for (i=l; i<=h; i++)
		{
			range.push_back(i);
		}

		std::vector<int> r = range;	// A disposable copy
		result.clear();
		
		for (i=0;i<k;i++)
		{
			s.push_back(0);
			result.push_back(r[s[i]]);
			r.erase(r.begin() + s[i]);
		}

	}
	

	// Generates the next variance
	// Returns zero if rolled back to the first one.
	bool next(int num = 1000)
	{
		if (this->next_state(num) == 0) return 0;

		std::vector<int> r = range;	// A disposable copy
		result.clear();
		
		int i; for (i=0;i<k;i++)
		{
			result.push_back(r[s[i]]);
			r.erase(r.begin() + s[i]);
		}
		return 1;
	}

	// Generates the next variance, but randomizes the state.
	// Always returns 1.
	bool random()
	{
		int i;
		for (i=0; i<k; i++)
		{
			s[i] = rand() % (n-i);
		}
		this->next();
		return 1;
	}
		

	// Returns a current result vector
	std::vector<int> get() 
	{
		return result;
	}
	// Returns a number of cases to go through
	long int cases()
	{
		long int ret = 1;
		int i;
		for (i=(n-k+1); i<=n; i++)
		{
			ret *= i;
		}
		return ret;
	}
};


std::vector<int> genstates (vari stv)
{
	std::vector<int> states;
	states.push_back(0);
	for (int j : stv.get()) states.push_back(j);
	states.push_back(1 << b+x-1);
	for (int j : stv.get()) states.push_back(j + (1 << b+x-1));
	if (p%2) states.pop_back();
	return states;
}

// Iterative lut filling function
// One iteration for one state progression.
// Returns a vector of LUTs. The vector is empty on failure.
std::vector<lut> fill_luts (std::vector<lut> luts, vari stv, std::vector<int> states, std::vector<comb> configs, const int csmap[], int d = 0)
{
	// One iteration of the function does the following:
	// 1  - Checks the validity of the current state progression (if depth > 0)
	// 2  -- If valid, goto 4
	// 3  -- If not, returns empty LUT
	// 4  - launch the next iteration (async)
	// 5  - Meanwhile, prepare the next state on its own depth
	// 6  - Waits for the return of the next iteration
	// 7  -- If not empty, return it yourself
	// 9  - if the state rolled over, return empty,
	
	int p2 = (p+1)/2;
	std::vector<lut> ll;
	bool ro = 0;		// Roll over

	//for (int i : states) std::cerr << i << "\t"; std::cout << "\n" ;
	
	// #1
	if (d > 0)
	{
		int i;
		for (i=0; i<b+x; i++)		// For each bit
		{
			int ma = (configs[i].intg() << b+x);
			if (luts[i].set(csmap[ma + states[d-1]], states[d] >> i & 1) == 0)
				return empty_luts;
			if ((d+p2) < states.size()) {
				if (luts[i].set(csmap[ma + states[d-1+p2]], states[d+p2] >> i & 1) == 0)
					return empty_luts;
			}
			// Special case - machine state loop back
			else if (luts[i].set(csmap[ma + states[p-1]], states[0] >> i & 1) == 0)
				return empty_luts;
		}
		// At this point the check was successful
		if (d+p2 >= states.size()) return luts;
	}

	while (1)
	{
		// #4
		//std::future<std::vector<lut>> ret = std::async(std::launch::async, fill_luts, luts, stv, states, configs, csmap, d+1);
		std::vector<lut> ret = fill_luts(luts, stv, states, configs, csmap, d+1);

		// #5
		ro = (stv.next(d) == 0);
		states = genstates(stv);

		// #6
		//ret.wait();
		//ll = ret.get();
		ll = ret;

		// #7
		if (ll.size() != 0)  return ll;

		// #9
		if (ro) return empty_luts;


	}
}

inline std::string bincout (int in, int w = 32)
{
	std::string s = std::bitset<32>(in).to_string();
	s.erase(0, 32-w);
	return s;
}

std::vector<int> parseconfig(int config)
{
	std::vector<int> rets;
	int in = 0;
	int i;
	for (i=0;i<b+x;i++)
	{
		if ((config >> i) & 1) 
		{
			rets.push_back(i);
		}
	}
	return rets;
}

std::vector<std::string> parseconfig_s(int config)
{
	std::vector<int> confv = parseconfig(config);
	std::vector<std::string> rets;
	int i;
	for (i=0;i<confv.size();i++)
	{
		rets.push_back("s[" + std::to_string(confv[i]) + "]");
	}
	return rets;
}

bool mass_next(std::vector<comb> & c)
{
	for (comb & i : c)
	{
		if (i.next()) return 1;
	}
	return 0;
}


void printmodule(std::vector<lut> & luts, std::vector<comb> & configs)
{
	std::cout << std::nounitbuf << "\n";
	std::cout << "// Auto generated divider / pseudo-random counter.\n";
	std::cout << "// States: " << p << "\n";
	std::cout << "module div_pr" << p << "(input wire clk, input wire rst, output reg [" << b+x-1 << ":0] out);\n";

	int j = 0;
	for (auto i : luts)
	{
		std::cout << "localparam lut" << j << "_data = 16'b" << i.str() << ";\n";
		j++;
	}

	std::cout << "wire [" << luts.size()-1 << ":0] lo;\n";

	std::vector<int> pcs;
	for (j=0;j<luts.size();j++)
	{
		pcs = configs[j].vec();
		std::cout << "SB_LUT4 lut" << j << " (.O(lo[" << j << "]), ";
		std::cout << ".I0(out[" << pcs.at(0) << "]), ";
		std::cout << ".I1(out[" << pcs.at(1) << "]), ";
		std::cout << ".I2(out[" << pcs.at(2) << "]), ";
		std::cout << ".I3(out[" << pcs.at(3) << "]));\n";
		std::cout << "defparam lut" << j << ".LUT_INIT = lut" << j << "_data;\n";
	}

	std::cout << "always @ (posedge clk) begin\n";	
	std::cout << "\tif (rst) out <= 0;\n";	
	std::cout << "\telse out <= lo;\n";	
	std::cout << "end\n";
	std::cout << "endmodule\n";
	std::cout << std::flush;
}

int main(int argc, char** argv)
{
	if (argc < 3) {
		std::cerr << "Usage:\n";
		std::cerr << "prdiv [period] [extrabits]\n";
		return 0;
	}
	p = int(atof(argv[1]));
	if (p > 10240) {
		std::cerr << p << "? Forget it..\n";
		return 0;
	}
	b = int(std::ceil(std::log2(p)));
	if (b < 4) b = 4;
	sx = int(atof(argv[2]));

	srand(time(NULL));
	
	int ps = ((p+1)/2)-1;	// A number of selectable states (without two fixed states)


	int i, j;
	for (i=0; i<=sx; i++)
	{
		x = i;
		//
		// Generating config-state map
		int csmap[int(std::pow(2,2*(b+x)))];
		comb gmc(4, b+x);
		while (1)
		{
			for (j=0;j<std::pow(2,b+x);j++)
			{
				csmap[(gmc.intg() << b+x) + j] = gmc.map(j);
			}
			if (!gmc.next()) break;
		}

		std::vector<comb> configs(b+x, comb(4, b+x));
		bool cro = 1;
		while (1)	// Config change
		{
			for (j=0; j<b+x; j++)
			{
				std::cerr << "C" << j << ":" << configs[j].str() << " ";
			}
			std::cerr << "\n";

			if (cro == 0) break;
			vari stv(1, std::pow(2,b+x-1)-1, ps);
			std::vector<int> states = genstates(stv);

			std::vector<lut> luts(b+x);
			luts = fill_luts(luts, stv, states, configs, csmap, 0);
			cro = mass_next(configs);
			if (luts.size() == 0) continue;
			
			// We got a winner!
			std::cerr << "Found it! \n";
			//std::cerr << "States: ";
			//for (int j : states) std::cerr << j << " ";
			//std::cerr << ";\n";
	
			for (j=0; j<b+x; j++)
			{
				std::cerr << "LUT" << j << ": " << luts[j].str() << "\t";
				std::cerr << "Config" << j << ": " << configs[j].str() << "\n";
			}
			printmodule(luts, configs);
			return 0;

		}
	}
		std::cerr << "Found nothing :(\n";
		std::cerr << "\a"; 			// BEL
		return 0;
}

