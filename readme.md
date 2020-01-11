# Scalable Open-Vote Network on Ethereum

# Installation 

 1. Install Nodejs from [https://nodejs.org/en/](https://nodejs.org/)
 2. Open terminal 
 3. Install Truffle Framework:  `npm install -g truffle`
 4. Install Ganache-cli: `npm install -g ganache-cli`
 5. Clone this repository and change directory to its path
 6. Install the required packages `npm i`
 7. Edit the file `node_modules\elliptic\lib\elliptic\curves.js`
 8. Paste the following code at the end
 > `defineCurve('bn256', {
type: 'short',
prime: null,
p: '30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47',
a: '0',
b: '3',
n: '30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001',
hash: hash.sha256,
gRed: false,
g: [
'1',
'2'
]
});`

# Execution
 1. Check the test code in the file `test\completeTest.js`
 2. Run the local Ethereum node: `ganache-cli -a 42` where 42 is the number of available accounts
 3. Run the command `truffle test` to view the result and the gas cost of each transaction

