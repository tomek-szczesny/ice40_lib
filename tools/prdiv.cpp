// Pseudo random divider
// LUT configuration finder
// by Tomek Szczęsny 2024
//
// This code is a mess.
// Do not attempt to understand any of that.
//

#include <bitset>
#include <cmath>
#include <iostream>
#include <string>
#include <vector>
	
int b = 0;		// Counter bitness (based on p)
int p = 0;		// Counter period  (cmd line arg)
int sx = 3;		// Max extra bits  (cmd line arg)

//const int t = b + x - 1;
int max = pow(2,b);


std::vector<int> results(2048);
int x = 0;	// Extra bits

int nextconfig (int i, bool s = 0)
{
	int j;
	int c;
	int target = s ? 3 : 4;
	while (1)
	{
		i++;
		i &= int(pow(2,b+x)-1);
		c = 0;
		for (j=0; j<b+x; j++)
		{
			c += (i >> j) & 1;
		}
		if (c == target) return i;
	}
}

int nextreactor (int i, int mode)
{
	if (mode == 0) return int(pow(2,16)-1) & (i+1);
	//if (mode == 1) return (i == 0)? 1 : int(pow(2,16)-1) & (i << 1);

	// Else... Mode is the minimum number of zeroes or ones
	// in the 16-bit reactor integer
	int j;
	int o;
	while (1)
	{
		i++;
		i &= int(pow(2,16)-1);
		o = 0;
		for (j=0; j<16; j++)
		{
			o += ((i >> j) & 1) ? 1 : 0;
		}
		if (o >= mode && 16-o >= mode) return i;
	}
	
}

inline void bincout (int in, int w = 32)
{
	std::string s = std::bitset<32>(in).to_string();
	s.erase(0, 32-w);
	std::cout<<s;
}

inline int lut(int in, int data)
{
	return (data & (1 << in) ? 1 : 0);
}

int eval(bool reset, long int data, int config1, int config2)
{
	static int d = 0;
	if (reset)
	{
		d = 0;
		return 0;
	}
	int in1 = 0;
	int in2 = 0;
	int i;
	int k = 0;
	for (i=0;i<b+x;i++)
	{
		if ((config1 >> i) & 1) 
		{
			in1 += ((d >> i) & 1) << i-k;
		}
		else k++;
	}
	k = 0;
	for (i=0;i<b+x;i++)
	{
		if ((config2 >> i) & 1) 
		{
			in2 += ((d >> i) & 1) << i-k;
		}
		else k++;
	}
	in2 += lut(in1, data % int(pow(2,16))) << 3;
	d = d << 1;
	d = d & int(pow(2,b+x)-1);
	if (config2 == 0) d += lut(in1, data % int(pow(2,16)));
	//if (lut(in2, data >> 16)) d = 0;
	else d += lut(in2, (data >> 16));
	return d;
}

bool check(int num)
{
	int i, j;
	for (i=0;i<num;i++)		// Check for period "num"
	{
		if (results[i] != results[i+num]) return 0;
	}
					// Check all states for uniqueness 
	for (i=0;i<num-1;i++)
	{
		for (j=i+1;j<num;j++)
		{
			if (results[j] == results[i]) return 0;
		}
	}

	return 1;
}

void showconfig (int config1, int config2)
{
		std::cout << "Config1: ";
		bincout(config1, b+x);
		std::cout << "\t";
		std::cout << "Config2: ";
		bincout(config2, b+x);
		//std::cout << "\n";
}


bool testloop(int mode , int config1, int config2, int mode1, int mode2)	// Returns 1 if succeeded
{
	// Mode 0 - only one reactor working
	// Mode 1 - both reactors work with the same value
	// Mode 2 - Brute force
	long int i, j, k;
	long int reactor1 = 0;
	long int reactor2 = 0;
	std::cout << "Test Loop " << ((mode) ? "with   " : "without") << " secondary LUT;\t";
	showconfig(config1, config2);
	std::cout << "\tUseful b: " << b << "; Extra b: " << x << "\n";

	while (reactor1 < nextreactor(reactor1, mode1))
	//for (i=0;i<std::pow(2,range);i++)
	{
		if (mode == 0 || mode == 1) reactor1 = nextreactor(reactor1, mode1);
		if (mode == 1) reactor2 = reactor1;
		if (mode == 2)
		{
			if (reactor2 < nextreactor(reactor2,mode2)) 
				reactor1 = nextreactor(reactor1, mode1);
			reactor2 = nextreactor(reactor2,mode2);
		}
		i = reactor1 + (reactor2 << 16);
		//std::cout << reactor1 << " " << reactor2 << "\n";

		results[0] = eval (1, 0, 0, 0); // reset
		for (j=1; j<2*p; j++)
		{
			results[j] = eval(0, i, config1, config2) & (max-1);
			if (j > 0 && results[j] == results[j-1]) goto next;
		}
		if (!check(p)) continue;
		for (j=0; j<2*p; j++)
		{
			results[j] = eval(0, i, config1, config2) & (max-1);
			if (j > 0 && results[j] == results[j-1]) goto next;
		}
		if (!check(p)) continue;
		
		// At this point check had succeeded.
		std::cout << "Found something!!\n";
		std::cout << "Reactor1: ";
		bincout(reactor1,16);
		std::cout << "\tReactor2: ";
		bincout(reactor2,16);
		std::cout << "\ti: ";
		bincout(i,32);
		std::cout << "\n";

		j = eval(1, 0, 0, 0);		// reset
		for (k=0; k<2*p+2; k++)
		{
			std::cout << "Output: " << j << " (" << j % max  << ")\n";
			j = eval(0, i, config1, config2) & (max-1); 
		}
		std::cout << "\a"; 		// BEL
		return 1;
next:		continue;
	}	
	return 0;
}

int main(int argc, char** argv)
{
	if (argc < 3) {
		std::cout << "Usage:\n";
		std::cout << "prdiv [period] [extrabits]\n";
		return 0;
	}
	p = int(atof(argv[1]));
	if (p > 1024) {
		std::cout << p << "? Forget it..\n";
		return 0;
	}
	b = int(std::ceil(std::log2(p)));
	if (b < 4) b = 4;
	max = pow(2,b);
	sx = int(atof(argv[2]));
	
	int config1 = 0;
	int config2 = 0;

	std::cout << "\n\n>>> Looking for a counter with period " << p << ".\n";
	
	
	//config1 = nextconfig(config1);
	//config2 = nextconfig(config2);
	
	int i;
	for (i=0; i<=sx; i++)
	{
		x = i;
		config1 = 1 << (b+x-1);
		while (config1 < nextconfig(config1))
		{
			config1 = nextconfig(config1);
			if (testloop(0, config1, config2, 0, 0)) return 0;
	 	}
	}
		//config1 = nextconfig(config1);
	
	std::cout << ">>> Single LUT solutions depleted. Adding Secondary LUT.\n";
	std::cout << ">>> Trying two LUTs with the same data.\n";
	for (i=0; i<=sx; i++)
	{
		x = i;
		config1 = 1;
		config2 = 1;
		if (i > 0) config1 = 1 << b+i-1;

		while (config2 < nextconfig(config2, 1))
		{
			config2 = nextconfig(config2, 1);
			config1 = 1;
			while (config1 < nextconfig(config1))
			{
				config1 = nextconfig(config1);
				if (testloop(1, config1, config2, 0, 0)) return 0;
			}
		}
	}
	std::cout << ">>> Brute forcing all possible LUT data combinations.\n";
	std::cout << ">>> This will take a while, lol...\n";
	for (i=0; i<=sx; i++)
	{
		x = i;
		config1 = 1;
		config2 = 1;
		if (i > 0) config1 = 1 << b+i-1;

		while (config2 < nextconfig(config2, 1))
		{
			config2 = nextconfig(config2, 1);
			config1 = 1;
			while (config1 < nextconfig(config1))
			{
				config1 = nextconfig(config1);
				if (testloop(2, config1, config2, 6, 6)) return 0;
			}
		}
	}
		std::cout << "Found nothing :(\n";
		std::cout << "\a"; 			// BEL
		return 0;
}

