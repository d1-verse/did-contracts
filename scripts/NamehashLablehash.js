const hre = require("hardhat");
// const namehash = require('eth-ens-namehash'); // namehash & normalize
// const tld = "test";
const ethers = hre.ethers;
const utils = ethers.utils;
const labelhash = (label) => utils.keccak256(utils.toUtf8Bytes(label))
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const ZERO_HASH = "0x0000000000000000000000000000000000000000000000000000000000000000";
const ROOT_NODE = "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

var sha3 = require('js-sha3').keccak_256
var uts46 = require('idna-uts46-hx')

function namehash (rootNode, inputName) {
    // Reject empty names:
    // var node = ''
    // for (var i = 0; i < 32; i++) {
    //    node += '00'
    // }

    var node = rootNode; // 'c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470'

    name = normalize(inputName)

    if (name) {
        var labels = name.split('.')

        for(var i = labels.length - 1; i >= 0; i--) {
            var labelSha = sha3(labels[i])
            node = sha3(Buffer.from(node + labelSha, 'hex'))
        }
    }

    return '0x' + node
}

function normalize(name) {
    return name ? uts46.toUnicode(name, {useStd3ASCII: true, transitional: false}) : name
}


async function main() {
    const root = labelhash("");
    console.log(root);

    const verse = labelhash("verse");
    console.log(verse);

    const verse_root = namehash('c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470', "verse");
    console.log(verse_root);

    const foobar_verse = namehash('c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470', "foobar.verse");
    console.log(foobar_verse);

    const www_foobar_verse = namehash('c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470', "www.foobar.verse");
    console.log(www_foobar_verse);

};


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });


/**


root: 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470

verse: 0xc14d68eb0d0a4df33c3656bc9e67e9cd0af9811668568c61c0c7e98ac830bdfa

foobar.verse: 0x02532798adbc24b7463d2984f38e9caa99661be4b772fbbaa15842d1a52ebf0a

alice.foobar.verse: 0xb8ed50a2dcd9fcb01a597b2c0ee72ba303309a1f7ec384ac4f666f87b08e3709

www.foobar.verse: 0x7ebb34bbb6b0dad285333443261c81c623b1ccd2052a9982eb0da01168915556

0x429ebD9365061DaBb853de89c134F9b79468a952

date +%s
1953978695

0x0000000000000000000000000000000000000000


 */
