// Pseudo random counter
// LUT configuration finder
// and Verilog module generator
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

std::vector<int> results(20480);
int x = 0;	// Extra bits

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
		if (confv.at(i) < b) rets.push_back("out[" + std::to_string(confv[i]) + "]");
		else rets.push_back("msb[" + std::to_string(confv[i]-b) + "]");
	}
	return rets;
}

void printmodule(int reactor1, int reactor2, int config1, int config2, int mode)
{
	std::cout << "\n";
	std::cout << "module ctr_pr" << p << "(input wire clk, input wire inc, output reg [" << b-1 << ":0] out = 0);\n";

	std::cout << "localparam lut1_data = 16'b" << bincout(reactor1,16) << ";\n";
	if (config2) std::cout << "localparam lut2_data = 16'b" << bincout(reactor2,16) << ";\n";

	std::cout << "wire lo1;";
	if (config2) std::cout << " wire lo2;"; std::cout << "\n";
	if (x) std::cout << "reg [" << x-1 << ":0] msb = 0;\n";

	std::vector<std::string> pcs = parseconfig_s(config1);
	std::cout << "SB_LUT4 lut1 (.O(lo1), .I0(" << pcs.at(0);
	std::cout << "), .I1(" << pcs.at(1) << "), .I2(";
	std::cout << pcs.at(2) << "), .I3(" << pcs.at(3) << "));\n";
	std::cout << "defparam lut1.LUT_INIT = lut1_data;\n";

	if (mode) {
		pcs = parseconfig_s(config2);
		std::cout << "SB_LUT4 lut2 (.O(lo2), .I0(" << pcs.at(0);
		std::cout << "), .I1(" << pcs.at(1) << "), .I2(" << pcs.at(2) << "), .I3(lo1));\n";
		std::cout << "defparam lut2.LUT_INIT = lut2_data;\n";
	}

	std::cout << "always @ (posedge clk) begin\n";	
	std::cout << "\tif (inc) begin\n";	
	if (x == 1)  std::cout << "\t\tmsb <= out[" << b-1 << "];\n";	
	if (x >= 2)  std::cout << "\t\tmsb <= {msb[" << x-2 << ":0], out[" << b-1 << "]};\n";
	             std::cout << "\t\tout[" << b-1 << ":1] <= out[" << b-2 << ":0];\n";
	if (config2) std::cout << "\t\tout[0] <= lo2;\n";
	else         std::cout << "\t\tout[0] <= lo1;\n";
	             std::cout << "\tend\n";
	             std::cout << "end\n";
	             std::cout << "endmodule\n";
}

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

bool testloop(int mode , int config1, int config2, int mode1, int mode2)	// Returns 1 if succeeded
{
	// Mode 0 - only one reactor working
	// Mode 1 - both reactors work with the same value
	// Mode 2 - Brute force
	long int i, j, k;
	long int reactor1 = 0;
	long int reactor2 = 0;
	std::cout << "//// Test Loop " << ((mode) ? "with   " : "without") << " secondary LUT;\t";
	std::cout << "Config1: " << bincout(config1, b+x) << "\t";
	std::cout << "Config2: " << bincout(config2, b+x);
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
		std::cout << "//// Found something!!\n";
		std::cout << "//// Reactor1: " << bincout(reactor1,16);
		std::cout << "\tReactor2: " << bincout(reactor2,16);
		std::cout << "\ti: " << bincout(i,32);
		std::cout << "\n";

		j = eval(1, 0, 0, 0);		// reset
		std::cout << "//// Output: " << j % max;
		for (k=0; k<2*p+2; k++)
		{
			j = eval(0, i, config1, config2) & (max-1); 
			std::cout << ", " << j % max;
		}
		printmodule(reactor1, reactor2, config1, config2, mode);
		std::cout << "\n//// (BEL character) \a\n"; 		// BEL
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
	if (p > 10240) {
		std::cout << p << "? Forget it..\n";
		return 0;
	}
	b = int(std::ceil(std::log2(p)));
	if (b < 4) b = 4;
	max = pow(2,b);
	sx = int(atof(argv[2]));
	
	int config1 = 0;
	int config2 = 0;

	std::cout << "//// >>> Looking for a counter with period " << p << ".\n";
	
	
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
	
	std::cout << "////>>> Single LUT solutions depleted. Adding Secondary LUT.\n";
	std::cout << "////>>> Trying two LUTs with the same data.\n";
	std::cout << "////>>> Assuming that each LUT contains exactly eight 1's.\n";
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
				if (testloop(1, config1, config2, 8, 8)) return 0;
			}
		}
	}
	std::cout << "////>>> Trying two LUTs with the same data.\n";
	std::cout << "////>>> Broadening search to any LUT values.\n";
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
	std::cout << "////>>> Brute forcing all possible LUT data combinations.\n";
	std::cout << "////>>> This will take a while, lol...\n";
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
				if (testloop(2, config1, config2, 0, 0)) return 0;
			}
		}
	}
		std::cout << "Found nothing :(\n";
		std::cout << "\a"; 			// BEL
		return 0;
}

