
const {expect} = require("chai");
const {ethers} = require("hardhat");
require('dotenv').config();

/*
Default hardhat network account, run "npx hardhat node" to get.

Account #0: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 (10000 ETH)
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

Account #1: 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 (10000 ETH)
Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

Account #2: 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc (10000 ETH)
Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

...

*/

const key0 = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const key1 = "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
const key2 = "5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";

describe('DID System:', () => {
    let deployerAsDao, verseOwner, operator, DB, CRegistrar, CResolver, NFT, SW, VR, dbAddr, cRegistrarAddr, nftAddr, swAddr, vrAddr, chainId;
    const ROOT_NODE = "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";
    const VERSE_NODE = "0xc14d68eb0d0a4df33c3656bc9e67e9cd0af9811668568c61c0c7e98ac830bdfa";
    const ZERO_NODE = "0x0000000000000000000000000000000000000000000000000000000000000000";

    // Use "beforeEach" or "before"
    before('Deploy all contracts', async () => {
        [deployerAsDao, verseOwner, operator, fooAcc, barAcc, aliceAcc, bobAcc] = await ethers.getSigners();
        chainId = (await ethers.provider.getNetwork()).chainId;

        const CoreDB = await ethers.getContractFactory('CoreDB');
        console.log('Deploying CoreDB...');
        DB = await CoreDB.deploy(deployerAsDao.address);
        await DB.deployed();
        console.log('CoreDB deployed to:', DB.address);

        const CoreRegistrar = await ethers.getContractFactory('CoreRegistrar');
        console.log('Deploying CoreRegistrar...');
        CRegistrar = await CoreRegistrar.deploy(DB.address);
        await CRegistrar.deployed();
        console.log('CoreRegistrar deployed to:', CRegistrar.address);

        const CoreResolver = await ethers.getContractFactory('CoreResolver');
        console.log('Deploying CoreResolver...');
        CResolver = await CoreResolver.deploy(DB.address);
        await CResolver.deployed();
        console.log('CoreResolver deployed to:', CResolver.address);

        const CoreNFT = await ethers.getContractFactory('CoreNFT');
        console.log('Deploying CoreNFT...');
        NFT = await CoreNFT.deploy(DB.address, "D1verse DID NFT", "D1DNFT", "https://static.schoolbuy.top/media/ula/");
        await NFT.deployed();
        console.log('CoreNFT deployed to:', NFT.address);

        const SensitiveWords = await ethers.getContractFactory('SensitiveWords');
        console.log('Deploying SensitiveWords...');
        SW = await SensitiveWords.deploy(DB.address);
        await SW.deployed();
        console.log('SensitiveWords deployed to:', SW.address);

        const VerseRegistrar = await ethers.getContractFactory('VerseRegistrar');
        console.log('Deploying VerseRegistrar...');
        VR = await VerseRegistrar.deploy(DB.address);
        await VR.deployed();
        console.log('VerseRegistrar deployed to:', VR.address);

        dbAddr = DB.address;
        cRegistrarAddr = CRegistrar.address;
        nftAddr = NFT.address;
        vrAddr = VR.address;
        swAddr = SW.address;

        console.log('CoreDB.setCoreRegistrar');
        const setCoreReg = await DB.setCoreRegistrar(CRegistrar.address);
        setCoreReg.wait();

        console.log('CoreDB.setCoreResolver');
        const setCoreRes = await DB.setCoreResolver(CResolver.address);
        setCoreRes.wait();

        console.log('CoreDB.setCoreNFT');
        const setNFT = await DB.setCoreNFT(NFT.address);
        setNFT.wait();

        console.log('CoreDB.setCoreSW');
        const setSW = await DB.setCoreSW(SW.address);
        setSW.wait();

        console.log('CoreRegistrar.registerSubnode');
        const register = await CRegistrar.registerSubnode(
            ROOT_NODE,
            deployerAsDao.address,
            1954177710,
            300,
            "0x0000000000000000000000000000000000000000",
            0,
            "verse",
            "0x00"
        );
        register.wait();

        console.log('CoreRegistrar.setRegistrar');
        const registrar = await CRegistrar.setRegistrar(VERSE_NODE, VR.address);
        registrar.wait();

        console.log('deployerAsDao.address: ', deployerAsDao.address);
        console.log('verseOwner.address: ', verseOwner.address);
        console.log('operator.address: ', operator.address);

    });

    process.on('exit', (code) => {
        console.log('EXITCODE:', code);
    });

    describe('Test NFT contract', async () => {

        it('NFT name', async () => {
            const ret = await NFT.name();
            expect(ret).equal("D1verse DID NFT");
        });

        it('NFT symbol', async () => {
            const ret = await NFT.symbol();
            expect(ret).equal("D1DNFT");
        });

        it('NFT symbol', async () => {
            const ret = await NFT.totalSupply();
            expect(ret).equal(2);
        });

        it('NFT Root owner', async () => {
            const ret = await NFT.ownerOf(ROOT_NODE);
            expect(ret).equal(deployerAsDao.address);
        });

        it('NFT Verse owner', async () => {
            const ret = await NFT.ownerOf(VERSE_NODE);
            expect(ret).equal(deployerAsDao.address);
        });

        it('NFT Verse owner', async () => {
            let transferFromTx = await NFT.connect(deployerAsDao).transferFrom(
                deployerAsDao.address,
                verseOwner.address,
                VERSE_NODE,
            );
            transferFromTx.wait();

            let ret = await NFT.ownerOf(VERSE_NODE);
            expect(ret).equal(verseOwner.address);

            let [ret1, ret2] = await CResolver.getReverse(verseOwner.address);
            console.log(ret1, ret2);
            expect(ret1).equal(VERSE_NODE);
            expect(ret2).equal('verse');

            transferFromTx = await NFT.connect(verseOwner).transferFrom(
                verseOwner.address,
                fooAcc.address,
                VERSE_NODE,
            );
            transferFromTx.wait();

            ret = await NFT.ownerOf(VERSE_NODE);
            console.log("a ", ret);
            expect(ret).equal(fooAcc.address);

            ret = await NFT.balanceOf(fooAcc.address);
            console.log("b ", ret);
            expect(ret).equal(1);

            ret = await NFT.balanceOf(verseOwner.address);
            console.log("c ", ret);
            expect(ret).equal(0);

            [ret1, ret2] = await CResolver.getReverse(verseOwner.address);
            console.log("d ", ret1, ret2);
            expect(ret1).equal(ZERO_NODE);
            expect(ret2).equal('');

            [ret1, ret2] = await CResolver.getReverse(fooAcc.address);
            console.log(ret1, ret2);
            expect(ret1).equal(VERSE_NODE);
            expect(ret2).equal('verse');

        });

        // TODO Burning NFT (root, verse...)
        // TODO Reclaim Node
        // TODO Lock/unLock Node, and transfer, burn
        // TODO expired transfer

    });

});

