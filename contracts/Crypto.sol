pragma solidity ^0.5.0;

contract Crypto {
    uint256 constant public gx = 19823850254741169819033785099293761935467223354323761392354670518001715552183;
    uint256 constant public gy = 15097907474011103550430959168661954736283086276546887690628027914974507414020;
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
    
    // function verifyZeroOrOne(uint[2] memory c, uint[2] memory H, uint[7] memory proof) public view returns (bool) {
    //     uint x = uint(keccak256(abi.encodePacked(c[0],c[1],proof[0],proof[1],proof[2],proof[3])))%q;
    //     uint[2] memory fza = ecAdd(ecMul(proof[4]),ecMul(proof[5],H));
    //     uint[2] memory zb = ecAdd(ecMul(0),ecMul(proof[6],H));
    //     uint[2] memory xCCa = ecAdd(ecMul(x,c),[proof[0],proof[1]]);
    //     uint[2] memory xfCCb = ecAdd(ecMul(Sub(x,proof[4]),c),[proof[2],proof[3]]);
    //     return Equal(fza,xCCa)&&Equal(zb,xfCCb);
    // }

    function verifyZeroOrOne(uint[2] memory c, uint[2] memory H, uint[18] memory proof) public view returns (bool ) {
        
        //  c = d1 + d2 ;
        // c= proof[13], d1 = proof [9], d2= proof [10]
        uint c_computed;
        c_computed = Add(proof[9], proof[10]);

        //  a1 = g ^ (r1). x ^ (d1) ;
        // a1 = proof[1,2]
        // r1 = proof[11]
        // x = proof[14,15]
        // d1 = proof[9]
        uint[2] memory a1_computed;
        a1_computed = ecAdd(ecMul(proof[11]), ecMul(proof[9],[proof[14], proof[15]]));
        

        // a2 = g ^ (r2) . x ^ (d2) ;
        // a2 = proof[5,6]
        // r2 = proof[12]
        // x = proof[14,15]
        // d2 = proof[10]
        uint[2] memory a2_computed;
        a2_computed = ecAdd(ecMul(proof[12]), ecMul(proof[10],[proof[14], proof[15]]));
        

        // b1 = h ^ (r1) . y ^ (d1)
        // b1 = proof [3,4]
        // H = H
        // r1 = proof [11]
        // y = proof [16,17]
        // d1 = proof [9]
        uint[2] memory b1_computed;
        b1_computed = ecAdd(ecMul(proof[11], H), ecMul(proof[9],[proof[16], proof[17]]));
        
        // b1 = h ^ (r2) . (y/g) ^ (d2)
        // b1 = proof[3,5]
        // h = H
        // r2 = proof[12]
        // y = proof [16,17]
        // d2 = proof [10]
        uint[2] memory b2_computed;
        b2_computed = ecAdd(ecAdd(ecMul(proof[12],H),ecMul(proof[10],[proof[16], proof[17]])),ecNeg(ecMul(proof[10])));
        
        return ((proof[13] == c_computed) && Equal(a1_computed, [proof[1], proof[2]]) &&
        Equal(a2_computed, [proof[5], proof[6]]) && Equal(b1_computed, [proof[3], proof[4]])
        && Equal(b2_computed, [proof[7], proof[8]]));
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