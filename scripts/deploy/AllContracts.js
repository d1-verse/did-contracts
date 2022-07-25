
function pressAnyKey(msg = 'Press any key to continue') {
    return new Promise((resolve) => {
        console.log(msg || 'Press any key to continue');
        process.stdin.setRawMode(true);
        process.stdin.resume();
        process.stdin.on('data', () => {
            process.stdin.destroy();
            resolve();
        });
    });
}

function sleep(time) {
    return new Promise((resolve) => {
        return setTimeout(resolve, time);
    })
}

async function main() {

    // console.log('Sleeping...');
    // await sleep(6000 * 3);
    // setTimeout(function(){console.log('sleeping...')},6000 * 20);

    // await pressAnyKey();
    // console.log('Sending Tx to Chain...');

    let CoreDB = await ethers.getContractFactory('CoreDB');
    console.log('Deploying CoreDB...');
    let DB = await CoreDB.deploy("0xe0d2F3AfDB8058615bE5f7D77D2ce1536e965Db5");
    await DB.deployed();
    console.log('CoreDB deployed to:', DB.address);

    let CoreRegistrar = await ethers.getContractFactory('CoreRegistrar');
    console.log('Deploying CoreRegistrar...');
    let CRegistrar = await CoreRegistrar.deploy(DB.address);
    await CRegistrar.deployed();
    console.log('CoreRegistrar deployed to:', CRegistrar.address);

    let CoreResolver = await ethers.getContractFactory('CoreResolver');
    console.log('Deploying CoreResolver...');
    let CResolver = await CoreResolver.deploy(DB.address);
    await CResolver.deployed();
    console.log('CoreResolver deployed to:', CResolver.address);

    let CoreNFT = await ethers.getContractFactory('CoreNFT');
    console.log('Deploying CoreNFT...');
    let NFT = await CoreNFT.deploy(DB.address, "d1verse DID", "d1verse DID", "https://www.d1verse.io/did-metadata/cube/");
    await NFT.deployed();
    console.log('CoreNFT deployed to:', NFT.address);

    let SensitiveWords = await ethers.getContractFactory('SensitiveWords');
    console.log('Deploying SensitiveWords...');
    let SW = await SensitiveWords.deploy(DB.address);
    await SW.deployed();
    console.log('SensitiveWords deployed to:', SW.address);

    let VerseRegistrar = await ethers.getContractFactory('VerseRegistrar');
    console.log('Deploying VerseRegistrar...');
    let VR = await VerseRegistrar.deploy(DB.address);
    await VR.deployed();
    console.log('VerseRegistrar deployed to:', VR.address);

    console.log('CoreDB.setCoreRegistrar');
    await DB.setCoreRegistrar(CRegistrar.address);
    console.log('CoreDB.setCoreResolver');
    await DB.setCoreResolver(CResolver.address);
    console.log('CoreDB.setCoreNFT');
    await DB.setCoreNFT(NFT.address);
    console.log('CoreDB.setCoreSW');
    await DB.setCoreSW(SW.address);

    console.log('CoreRegistrar.registerSubnode');
    await CRegistrar.registerSubnode(
        "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
        "0xe0d2F3AfDB8058615bE5f7D77D2ce1536e965Db5",
        1954177710,
        300,
        "0x0000000000000000000000000000000000000000",
        0,
        "verse",
        "0x00"
    );
    console.log('CoreRegistrar.setRegistrar');
    await CRegistrar.setRegistrar("0xc14d68eb0d0a4df33c3656bc9e67e9cd0af9811668568c61c0c7e98ac830bdfa", VR.address);

}

/*

https://testnet.hecoinfo.com/address/0x429ebD9365061DaBb853de89c134F9b79468a952

https://testnet.hecoinfo.com/address/0xb694FD4369516E2d1b1D9a46653D539b805fE8C2

0xc14d68eb0d0a4df33c3656bc9e67e9cd0af9811668568c61c0c7e98ac830bdfa verse

0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 root

    function registerSubnode(
        bytes32 parent,
        address owner,
        uint64 expire,
        uint64 ttl,
        address payment,
        uint256 cost,
        string memory name
    ) external  returns (bytes32);

*/

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.log(err);
        process.exit(1);
    });


