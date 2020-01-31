const EC = require('elliptic').ec
const BN = require('bn.js')
const abi = require('ethereumjs-abi')
const { keccak256 } = require('ethereumjs-util');
const secureRandom = require('secure-random')
var group = new EC('bn256')

// generate proof in case of message Zero. 
function create1outof2ZKPNoVote ( m, r, H, i) {
    // m is the vote
    // r is x_i
    // H is Y_i
    // i is the voter id 

    // Generate the commit 
    c = group.g.mul(m).add(H.mul(r));    

    // generate the randoms w,r2, d2 from Zq
    w = new BN(secureRandom.randomBuffer(31)).mod(group.n)
    r2 = new BN(secureRandom.randomBuffer(31)).mod(group.n)
    d2 = new BN(secureRandom.randomBuffer(31)).mod(group.n)

    // Calculate X = g^(x_i);
    X = group.g.mul(r);

    // Calculate Y=Y_i^(x_i);
    Yzkp =  H.mul(new BN (r));
        
    // calculate a1=g^(w)
    a1= group.g.mul(w);

    // calculate b1
    b1 = H.mul(w);

    // calculate a2
    a2 = group.g.mul(r2).add(X.mul(d2)); 
    
    // calculate b2 (need to check)
    b2 =  H.mul(r2).add(Yzkp.mul(d2)).add(group.g.mul(d2).neg());
    
    data = [i, X.getX() , X.getY(), Yzkp.getX(), Yzkp.getY(), a1.getX(), a1.getY(), b1.getX(), b1.getY(), a2.getX(), a2.getY(), b2.getX(), b2.getY()];
    encodedData = abi.rawEncode(['uint[13]'],[data]);
    challenge = (new BN(keccak256(encodedData)));
    challenge =challenge.mod(group.n);
    
    // calculate the d1
    d1 = challenge.sub(d2).mod(group.n);
    if(d1.isNeg())
        d1= d1.add(group.n)
    // calculate r1
    r1 = w.sub(r.mul(d1)).mod(group.n);
    if(r1.isNeg())
        r1= r1.add(group.n)

    return {commit: c, proof:[w, a1.getX(), a1.getY(), b1.getX(), b1.getY(), a2.getX(), a2.getY(),  b2.getX(), b2.getY(), d1, d2, r1, r2, challenge, X.getX(), X.getY(), Yzkp.getX(), Yzkp.getY()]}

}

// generate proof in case of message zero.
function create1outof2ZKPYesVote ( m, r, H, i) {

    // m is the vote
    // r is x_i
    // H is Y_i
    // i is the voter id 

    // Generate the commit 
    c = group.g.mul(m).add(H.mul(r));    

    // generate the randoms w,r2, d2 from Zq
    w = new BN(secureRandom.randomBuffer(31)).mod(group.n)
    r1 = new BN(secureRandom.randomBuffer(31)).mod(group.n)
    d1 = new BN(secureRandom.randomBuffer(31)).mod(group.n)

    // Calculate X = g^(x_i);
    X = group.g.mul(r);    

    // Calculate Y=Y_i^(x_i).g;    
    Yzkp =  H.mul(r).add(group.g); 
    
    // calculate a1
    a1 = group.g.mul(r1).add(X.mul(d1));

    // calculate b1
    b1 = H.mul(r1).add(Yzkp.mul(d1));

    // calculate a2 
    a2 = group.g.mul(w);
    
    // calculate b2 
    b2 = H.mul(w);

    // computing the hash
    data = [i, X.getX() , X.getY(), Yzkp.getX(), Yzkp.getY(), a1.getX(), a1.getY(), b1.getX(), b1.getY(), a2.getX(), a2.getY(), b2.getX(), b2.getY()];
    encodedData = abi.rawEncode(['uint[13]'],[data]);
    challenge = (new BN(keccak256(encodedData)));
    challenge =challenge.mod(group.n);

    // calculate the d2
    d2 = challenge.sub(d1).mod(group.n);
    if(d2.isNeg())
        d2= d2.add(group.n)

    // calculate r2
    r2 = w.sub(r.mul(d2)).mod(group.n);
    if(r2.isNeg())
        r2= r2.add(group.n)

    return {commit: c, proof:[w, a1.getX(), a1.getY(), b1.getX(), b1.getY(), a2.getX(), a2.getY(),  b2.getX(), b2.getY(), d1, d2, r1, r2, challenge, X.getX(), X.getY(), Yzkp.getX(), Yzkp.getY()]}

}

function commitAndProveZeroOrOne( m, r, H, i) {
    if (m==0)
    {         
        proof=create1outof2ZKPNoVote( m, r, H, i);
                
    }

    else if (m==1)
    {
        proof=create1outof2ZKPYesVote( m, r, H, i);
        
    }
    else
    {
        
    }

    return (proof);
}


function genVotingKeyAndProofs(count) {
    result = []
    for(i =0 ;i<count;i++) {
        key = group.genKeyPair()
        a = group.genKeyPair()
        data = [key.getPublic().getX(),key.getPublic().getY(),a.getPublic().getX(),a.getPublic().getY()]
        input = abi.rawEncode(['uint[4]'],[data])
        c = new BN(keccak256(input))
        c = c.mod(group.n)
        c = c.mul(key.getPrivate()).mod(group.n)
        z = c.add(a.getPrivate()).mod(group.n)
        result.push({x: key.getPrivate(),
            xG: key.getPublic(),
            v: Math.floor(Math.random()*2),
            Y: null,
            c: null,
            proofDL: [a.getPublic().getX(),a.getPublic().getY(),z],
            proof01:null
            })
    }
    return result
}

function genVoteCommitmentsAndProofs(votingKeys) {
    commitments = []
    num = group.g.add(group.g.neg())
    den = group.g.add(group.g.neg())
    for(i =0; i <votingKeys.length; i++)
        den = den.add(votingKeys[i].xG)
    for(i=0; i<votingKeys.length;i++) {
        den = den.add(votingKeys[i].xG.neg())
        votingKeys[i].Y = num.add(den.neg())
        r = commitAndProveZeroOrOne(votingKeys[i].v,votingKeys[i].x,votingKeys[i].Y, i )
        votingKeys[i].c= r.commit
        votingKeys[i].proof01 = r.proof
        num = num.add(votingKeys[i].xG)
    }
}
function genTestData(length) {
    res = genVotingKeyAndProofs(length);
    genVoteCommitmentsAndProofs(res);
    return res;
}
module.exports = {
    genTestData
  }

//   data = genTestData(2)

//   sum = 0
//   acc = group.g.add(group.g.neg())
//   vr = data[0]
//   console.log(`["${vr.c.getX().toString()}","${vr.c.getY().toString()}"],["${vr.Y.getX().toString()}","${vr.Y.getX().toString()}"],["${vr.proof01[0]}","${vr.proof01[1]}","${vr.proof01[2]}","${vr.proof01[3]}","${vr.proof01[4]}","${vr.proof01[5]}","${vr.proof01[6]}"]`)
//   for(i =0;i<2;i++) {
//       sum+=data[i].v
//       acc = acc.add(data[i].c)
//   }
//   t = group.g.mul(sum)
//   console.log(t.eq(acc))
