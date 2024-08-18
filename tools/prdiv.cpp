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
#include <stdlib.h>     /* srand, rand */
#include <iostream>
#include <string>
#include <time.h>	// For srand
#include <vector>
	
int p = 0;		// Counter period  (cmd line arg)
int b = 0;		// Counter bitness (based on p)
int sx = 3;		// Max extra bits  (cmd line arg)
int x = 0;		// Extra bits

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
		const int max = std::pow(2,16)-1;
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



// Return the state number in which emplacement failed.
// Returns 0 if succeeded.
int fill_luts (std::vector<lut> & luts, std::vector<int> & states, std::vector<comb> & configs, int csmap[])
{
	int i, j;
	int p2 = (p+1)/2;
	int map;

	for (i=0; i<b+x; i++) luts[i].clear();

	for (j=1; j<(p2)+1; j++)		// For each state
	{
		for (i=0; i<b+x; i++)		// For each bit
		{
			int ma = (configs[i].intg() << b+x);
			if (luts[i].set(csmap[ma + states[j-1]], states[j] >> i & 1) == 0)
				return j + (i << 16);
			if ((j+p2) < states.size()) {
				if (luts[i].set(csmap[ma + states[j-1+p2]], states[j+p2] >> i & 1) == 0)
					return j + (i << 16);
			}
			// Special case - machine state loop back
			else if (luts[i].set(csmap[ma + states[p-1]], states[0] >> i & 1) == 0)
				return j + (i << 16);
		}
	}
	return 0;
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

void printmodule(std::vector<lut> & luts, std::vector<int> & states, std::vector<comb> & configs)
{
	std::cout << std::nounitbuf << "\n";
	std::cout << "// Auto generated divider / pseudo-random counter.\n";
	//std::cout << "// It took " << t << " seconds to find this configuration.\n";
	std::cout << "// States:";
	for (auto i : states) std::cout << " " << i;
	std::cout << "\n";
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
	std::vector<int> states;

	int gws = 0;		// Greatest working state
	int tb = 0;		// Troublesome bit
	int ltb = 0;		// Last troublesome bit
			

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
		std::vector<lut> luts(b+x);

		vari stv(1, std::pow(2,b+x-1)-1, ps);
		long int cases = stv.cases();
		long int cc = 0;
		auto timer = std::chrono::high_resolution_clock::now() + std::chrono::seconds(10);
		//while (mass_next(configs))
		while (1)		// State list
		{
			cc++;

			if (timer < std::chrono::high_resolution_clock::now())
			{
				timer += std::chrono::seconds(10);
				for (int j : states) std::cerr << j << " ";
				std::cerr << "\t";
				for (j=0; j<b+x; j++)
				{
					std::cerr << "C" << j << ":" << configs[j].str() << " ";
				}
				std::cerr << "\n";
			}

			states.clear();
			states.push_back(0);
			for (int j : stv.get()) states.push_back(j);
			states.push_back(1 << b+x-1);
			for (int j : stv.get()) states.push_back(j + (1 << b+x-1));
			if (p%2) states.pop_back();

			while (1)	// Config rollover
			{
				gws = 0;


				int fl = fill_luts(luts, states, configs, csmap);
				if (fl % (1 << 16) > gws) gws = fl % (1 << 16);

				if (fl == 0)
				{
					// We have a winner!
					std::cerr << "Found it! \n";
					std::cerr << "States: ";
					for (int j : states) std::cerr << j << " ";
					std::cerr << ";\n";
			
					for (j=0; j<b+x; j++)
					{
						std::cerr << "LUT" << j << ": " << luts[j].str() << "\t";
						std::cerr << "Config" << j << ": " << configs[j].str() << "\n";
					}
					printmodule(luts, states, configs);
					return 0;
				}

				tb = fl/(1 << 16);
				if (!configs[tb].next())
				{
					if (tb == ltb) break;
					else ltb = tb;
				}
			}
		if (stv.next(gws-1) == 0) break;
		}
	}
		std::cerr << "Found nothing :(\n";
		std::cerr << "\a"; 			// BEL
		return 0;
}

