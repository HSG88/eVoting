const EC = require('elliptic').ec
const BN = require('bn.js')
const abi = require('ethereumjs-abi')
const { keccak256 } = require('ethereumjs-util');
const secureRandom = require('secure-random')
var group = new EC('bn256')

function commitAndProveZeroOrOne( m, r, H) {
    c = group.g.mul(m).add(H.mul(r))
    a =new BN(secureRandom.randomBuffer(31)).mod(group.n)
    s =new BN(secureRandom.randomBuffer(31)).mod(group.n)
    t =new BN(secureRandom.randomBuffer(31)).mod(group.n)
    ca = group.g.mul(a).add(H.mul(s))
    am = a.mul(new BN(m)).mod(group.n)
    cb = group.g.mul(am).add(H.mul(t))
    dd = [c.getX(),c.getY(),ca.getX(),ca.getY(),cb.getX(),cb.getY()]
    input = abi.rawEncode(['uint[6]'],[dd])
    x = (new BN(keccak256(input)))
    x =x.mod(group.n)
    f = new BN(m).mul(x).mod(group.n)
    f= f.add(a).mod(group.n)
    za = r.mul(x).mod(group.n)
    za = za.add(s).mod(group.n)
    zb = x.sub(f).mod(group.n)
    if(zb.isNeg())
        zb= zb.add(group.n)
    zb = r.mul(zb).mod(group.n)
    zb = zb.add(t).mod(group.n)
    return {commit: c, proof:[ca.getX(),ca.getY(),cb.getX(),cb.getY(),f,za,zb]}
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
        r = commitAndProveZeroOrOne(votingKeys[i].v,votingKeys[i].x,votingKeys[i].Y )
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
