pragma solidity ^0.5.0;

contract Crypto {
    uint256 constant public gx = 1;
    uint256 constant public gy = 2;
    uint256 constant public q =  21888242871839275222246405745257275088548364400416034343698204186575808495617; // curve order
    uint256 constant public p =  21888242871839275222246405745257275088696311157297823662689037894645226208583; // curve modulus

    function ecAdd(uint[2] memory p1, uint[2] memory p2) public view returns (uint[2] memory r) {
        uint256[4] memory input = [p1[0],p1[1],p2[0],p2[1]];
        assembly {
            if iszero(staticcall(not(0), 6, input, 0x80, r, 0x40)) {
                revert(0, 0)
            }
        }
    }
   /* function ecSub(uint[2] memory p1, uint[2] memory p2) public view returns (uint[2] memory r) {
        return ecAdd(p1, ecNeg(p2));
    }*/

    function ecMul(uint s, uint[2] memory p1) public view returns (uint[2] memory r) {
        uint256[3] memory input = [p1[0],p1[1],s];
        assembly {
            if iszero(staticcall(not(0), 7, input, 0x60, r, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function ecMul(uint s) public view returns (uint[2] memory r) {
        r = ecMul(s,[gx,gy]);
    }

    function ecNeg(uint[2] memory p1) public pure returns (uint[2] memory) {
        if (p1[0] == 0 && p1[1] == 0)
            return p1;
        p1[1] = p - p1[1];
        return p1;
    }

    function Add(uint x, uint y) public pure returns (uint) {
        return addmod(x, y, q);
    }

    function Mul(uint x, uint y) public pure returns (uint) {
        return mulmod(x, y, q);
    }
    /*function Inv(uint x) public pure returns (uint) {
        uint a = x;
        if (a == 0)
            return 0;
        if (a > q)
            a = a % q;
        int t1;
        int t2 = 1;
        uint r1 = q;
        uint r2 = a;
        uint qq;
        while (r2 != 0) {
            qq = r1 / r2;
            (t1, t2, r1, r2) = (t2, t1 - int(qq) * t2, r2, r1 - qq * r2);
        }
        if (t1 < 0)
            return (q - uint(-t1));
        return uint(t1);
    }*/

    /*function Mod(uint256 x) public pure returns (uint256) {
        return x % q;
    }*/

    function Sub(uint256 x, uint256 y) public pure returns (uint256) {
        return x >= y ? x - y : q - y + x;
    }

    /*function Neg(uint256 x) public pure returns (uint256) {
        return q - x;
    }*/
    function Equal(uint[2] memory x, uint[2] memory y) public pure returns (bool) {
        return x[0] == y[0] && x[1] == y[1];
    }

    /*function proveDL(uint[2] memory xG, uint x, uint a) public view returns (uint[3] memory proof) {
        uint[2] memory aG = ecMul(a);
        uint c = uint(keccak256(abi.encodePacked(xG,aG)));
        uint z = Add(a, Mul(c,x));
        proof[0] = aG[0];
        proof[1] = aG[1];
        proof[2] = z;
    }*/

    function verifyDL(uint[2] memory xG, uint[3] memory proof) public view returns (bool) {
        uint c = uint(keccak256(abi.encodePacked(xG,[proof[0],proof[1]])));
        uint[2] memory zG = ecMul(proof[2]);
        uint[2] memory temp = ecMul(c,xG);
        temp = ecAdd(temp,[proof[0],proof[1]]);
        return Equal(temp, zG);
    }
    function commit(uint v, uint x, uint[2] memory Y) public view returns (uint[2] memory c) {
        uint[2] memory vG = ecMul(v);
        uint[2] memory xY = ecMul(x, Y);
        c = ecAdd(xY,vG);
    }
   /* function proveZeroOrOne(uint[2] memory c, uint[2] memory H, uint m, uint r, uint a, uint s, uint t)
     public view returns (uint[7] memory proof) {
        uint[2] memory ca = commit(a,s,H);
        uint am = Mul(a,m);
        uint[2] memory cb = commit (am, t, H);
        uint x = uint(keccak256(abi.encodePacked(c,ca,cb)));
        proof[0] = ca[0];
        proof[1] = ca[1];
        proof[2] = cb[0];
        proof[3] = cb[1];
        proof[4] = Add(Mul(m,x),a); //f
        proof[5] = Add(Mul(r,x),s);//za
        proof[6] = Add(Mul(r,(Sub(x,proof[4]))),t);//zb
    }*/
    function verifyZeroOrOne(uint[2] memory c, uint[2] memory H, uint[7] memory proof) public view returns (bool) {
        uint x = uint(keccak256(abi.encodePacked(c[0],c[1],proof[0],proof[1],proof[2],proof[3])))%q;
        uint[2] memory fza = ecAdd(ecMul(proof[4]),ecMul(proof[5],H));
        uint[2] memory zb = ecAdd(ecMul(0),ecMul(proof[6],H));
        uint[2] memory xCCa = ecAdd(ecMul(x,c),[proof[0],proof[1]]);
        uint[2] memory xfCCb = ecAdd(ecMul(Sub(x,proof[4]),c),[proof[2],proof[3]]);
        return Equal(fza,xCCa)&&Equal(zb,xfCCb);
    }
    function verifyMerkleProof(bytes32[] memory proof, bytes32 root, bytes32 leaf) public pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }
}