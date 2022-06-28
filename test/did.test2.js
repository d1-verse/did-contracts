
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

tokenId: 89477152217924674838424037953991966239322087453347756267410168184682657981552
root: 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470

tokenId: 87433151119139180362589798212782878001775431722266472738173765202774317907450
verse: 0xc14d68eb0d0a4df33c3656bc9e67e9cd0af9811668568c61c0c7e98ac830bdfa

tokenId: 1051547287858981088042974819189773567500778583121589627733932273341958110986
foobar.verse: 0x02532798adbc24b7463d2984f38e9caa99661be4b772fbbaa15842d1a52ebf0a

tokenId: 83644863424150974713429932429731041629226182921035885854503447482710799300361
alice.foobar.verse: 0xb8ed50a2dcd9fcb01a597b2c0ee72ba303309a1f7ec384ac4f666f87b08e3709
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
    const TEST_NODE =  "0xe7cdf4bd550f394618b4dfd12ccf68a8b7c5f83d93e958f16496b53ea22389b4";

    // Use "beforeEach" or "before"
    before('Deploy all contracts', async () => {
        [deployerAsDao, verseOwner, operator, fooAcc, barAcc, otherAcc, aliceAcc, bobAcc] = await ethers.getSigners();
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
        const registerSubnode = await CRegistrar.registerSubnode(
            ROOT_NODE,
            deployerAsDao.address,
            1954177710,
            300,
            "0x0000000000000000000000000000000000000000",
            0,
            "verse",
            "0x00"
        );
        registerSubnode.wait();

        console.log('CoreRegistrar.setRegistrar');
        const setRegistrar = await CRegistrar.setRegistrar(VERSE_NODE, VR.address);
        setRegistrar.wait();

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

        it('NFT totalSupply', async () => {
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

        it('Transfer verse node', async () => {
            let transferFromTx = await NFT.connect(deployerAsDao).transferFrom(
                deployerAsDao.address,
                verseOwner.address,
                VERSE_NODE,
            );
            transferFromTx.wait();

            let ret = await NFT.ownerOf(VERSE_NODE);
            expect(ret).equal(verseOwner.address);

            let [ret1, ret2] = await CResolver.getReverse(verseOwner.address);
            expect(ret1).equal(VERSE_NODE);
            expect(ret2).equal('verse');

            transferFromTx = await NFT.connect(verseOwner).transferFrom(
                verseOwner.address,
                fooAcc.address,
                VERSE_NODE,
            );
            transferFromTx.wait();

            ret = await NFT.ownerOf(VERSE_NODE);
            expect(ret).equal(fooAcc.address);

            ret = await NFT.balanceOf(fooAcc.address);
            expect(ret).equal(1);

            ret = await NFT.balanceOf(verseOwner.address);
            expect(ret).equal(0);

            [ret1, ret2] = await CResolver.getReverse(verseOwner.address);
            expect(ret1).equal(ZERO_NODE);
            expect(ret2).equal('');

            [ret1, ret2] = await CResolver.getReverse(fooAcc.address);
            expect(ret1).equal(VERSE_NODE);
            expect(ret2).equal('verse');
        });

        it('Burn root node', async () => {
            let totalSupply = await NFT.totalSupply();
            expect(totalSupply).equal(2);

            let balance = await NFT.balanceOf(deployerAsDao.address);
            expect(balance).equal(1);

            let owner = await NFT.ownerOf("0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470");
            expect(owner).equal(deployerAsDao.address);

            const burn = await NFT.connect(deployerAsDao).burn("0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470");
            burn.wait();

            balance = await NFT.balanceOf(deployerAsDao.address);
            expect(balance).equal(0);

            totalSupply = await NFT.totalSupply();
            expect(totalSupply).equal(1);
        });

        it('Burn verse node', async () => {
            let balance = await NFT.balanceOf(fooAcc.address);
            expect(balance).equal(1);

            let owner = await NFT.ownerOf("0xc14d68eb0d0a4df33c3656bc9e67e9cd0af9811668568c61c0c7e98ac830bdfa");
            expect(owner).equal(fooAcc.address);

            const burn = await NFT.connect(fooAcc).burn("0xc14d68eb0d0a4df33c3656bc9e67e9cd0af9811668568c61c0c7e98ac830bdfa");
            burn.wait();

            balance = await NFT.balanceOf(fooAcc.address);
            expect(balance).equal(0);

            totalSupply = await NFT.totalSupply();
            expect(totalSupply).equal(0);
        });

        it('Register foobar.verse', async () => {
            const setOperator = await DB.setOperator(operator.address, true);
            await setOperator.wait();

            const isOperater = await DB.isOperator(operator.address);
            expect(isOperater).equal(true);

            const initNode = await DB.connect(operator).initNode(ROOT_NODE, ROOT_NODE, deployerAsDao.address, "17446744073709552000", false);
            initNode.wait();

            const registerSubnode = await CRegistrar.registerSubnode(
                ROOT_NODE,
                deployerAsDao.address,
                1954177710,
                300,
                "0x0000000000000000000000000000000000000000",
                0,
                "verse",
                "0x00"
            );
            registerSubnode.wait();

            console.log('CoreRegistrar.setRegistrar');
            const setRegistrar = await CRegistrar.setRegistrar(VERSE_NODE, VR.address);
            setRegistrar.wait();

            const register = await VR.register(
                fooAcc.address,
                // 1954177610,
                300,
                "foobar",
                "0x01"
            );
            register.wait();
            let owner = await NFT.ownerOf("0x02532798adbc24b7463d2984f38e9caa99661be4b772fbbaa15842d1a52ebf0a");
            expect(owner).equal(fooAcc.address);
        });

        it('Burn the foobar.verse node', async () => {
            const burn = await NFT.connect(fooAcc).burn("0x02532798adbc24b7463d2984f38e9caa99661be4b772fbbaa15842d1a52ebf0a");
            burn.wait();

            let balance = await NFT.balanceOf(fooAcc.address);
            expect(balance).equal(0);
        });

        it("Create the node if the node is not expired, should failed", async () => {
            let register = await VR.register(
                fooAcc.address,
                // 1854177710,
                300,
                "foobar",
                "0x01"
            );
            register.wait();

            let owner = await NFT.ownerOf("0x02532798adbc24b7463d2984f38e9caa99661be4b772fbbaa15842d1a52ebf0a");
            expect(owner).equal(fooAcc.address);

            try {
                register = await VR.register(
                    otherAcc.address,
                    // 1944177710,
                    300,
                    "foobar",
                    "0x01"
                );
                register.wait();
            } catch (e) {
                console.log("\n\033[0;31m%s\033[0m", e);
            }

            const approve = await NFT.connect(fooAcc).approve(barAcc.address, "0x02532798adbc24b7463d2984f38e9caa99661be4b772fbbaa15842d1a52ebf0a");
            approve.wait();
            const addr = await NFT.getApproved("0x02532798adbc24b7463d2984f38e9caa99661be4b772fbbaa15842d1a52ebf0a");
            expect(addr).equal(barAcc.address);

            const safeTransFrom = await NFT.connect(barAcc)["safeTransferFrom(address,address,uint256)"](
                fooAcc.address,
                barAcc.address,
                "0x02532798adbc24b7463d2984f38e9caa99661be4b772fbbaa15842d1a52ebf0a"
            );
            safeTransFrom.wait();

            owner = await NFT.ownerOf("0x02532798adbc24b7463d2984f38e9caa99661be4b772fbbaa15842d1a52ebf0a")
            expect(owner).equal(barAcc.address);
        });

        it("Create the node if the node has expired, should success", async () => {
            let isOperater = await VR.isOperator(operator.address);
            expect(isOperater).equal(false);

            const setOp = await VR.connect(deployerAsDao).setOperator(operator.address, true);
            setOp.wait();

            isOperater = await VR.isOperator(operator.address);
            expect(isOperater).equal(true);

            const setFree = await VR.connect(operator).setFreeDuration(1);
            setFree.wait();
            // console.log(await setFree.wait());

            const burn = await NFT.connect(barAcc).burn("0x02532798adbc24b7463d2984f38e9caa99661be4b772fbbaa15842d1a52ebf0a");
            burn.wait();

            let balance = await NFT.balanceOf(barAcc.address);
            expect(balance).equal(0);

            let timestamp = Math.floor(Date.now() / 1000); // 秒
            let register = await VR.register(
                fooAcc.address,
                // timestamp + 30,
                300,
                "foobar",
                "0x01"
            );
            register.wait();

            let owner = await NFT.ownerOf("0x02532798adbc24b7463d2984f38e9caa99661be4b772fbbaa15842d1a52ebf0a");
            expect(owner).equal(fooAcc.address);

            await new Promise(resolve => setTimeout(resolve, 5000));
            timestamp = Math.floor(Date.now() / 1000); // 秒

            try {
                register = await VR.register(
                    barAcc.address,
                    // timestamp + 500,
                    300,
                    "foobar",
                    "0x01"
                );
                register.wait();
            } catch (e) {
                console.log("\n\033[0;31m%s\033[0m", e);
            }

            owner = await NFT.ownerOf("0x02532798adbc24b7463d2984f38e9caa99661be4b772fbbaa15842d1a52ebf0a");
            expect(owner).equal(barAcc.address);

            balance = await NFT.balanceOf(barAcc.address);
            expect(balance).equal(1);
        });

        it("Locked verse node to burn，should failed", async () => {
            const lockNode = await DB.connect(operator).lockNode(VERSE_NODE, true);
            lockNode.wait();
            const isLocked = await DB.nodeLock(VERSE_NODE);
            expect(isLocked).equal(true);

            let owner = await NFT.ownerOf(VERSE_NODE);
            expect(owner).equal(deployerAsDao.address);

            // const approve = await NFT.connect(deployerAsDao).approve(fooAcc.address, VERSE_NODE);
            // approve.wait();
            // const addr = await NFT.getApproved(VERSE_NODE);
            // expect(addr).equal(fooAcc.address);

            try {
                let burn = await NFT.connect(deployerAsDao).burn(VERSE_NODE);
                burn.wait();
            } catch (e) {
                console.log("\n\033[0;31m%s\033[0m", e);
            }

            owner = await NFT.ownerOf(VERSE_NODE);
            expect(owner).equal(deployerAsDao.address);
        });

        it("Locked verse node to transfer，should failed", async () => {
           const isLocked = await DB.nodeLock(VERSE_NODE);
           expect(isLocked).equal(true);

           let owner = await NFT.ownerOf(VERSE_NODE);
           expect(owner).equal(deployerAsDao.address);

           try {
               const transferFrom = await NFT.connect(deployerAsDao).transferFrom(
                   deployerAsDao.address,
                   fooAcc.address,
                   VERSE_NODE
               );
               transferFrom.wait();
           } catch (e) {
               console.log("\n\033[0;31m%s\033[0m", e);
           }

           owner = await NFT.ownerOf(VERSE_NODE);
           expect(owner).equal(deployerAsDao.address);
        });

        it("Unlocked verse node to transfer，should success", async () => {
            const isLocked = await DB.nodeLock(VERSE_NODE);
            expect(isLocked).equal(true);

            const nodeLock = await DB.connect(operator).lockNode(VERSE_NODE, false);
            nodeLock.wait();

            let owner = await NFT.ownerOf(VERSE_NODE);
            expect(owner).equal(deployerAsDao.address);

            const approve = await NFT.connect(deployerAsDao).approve(fooAcc.address, VERSE_NODE);
            approve.wait();
            const addr = await NFT.getApproved(VERSE_NODE);
            expect(addr).equal(fooAcc.address);

            const safeTransFrom = await NFT.connect(fooAcc)["safeTransferFrom(address,address,uint256)"](
                deployerAsDao.address,
                fooAcc.address,
                VERSE_NODE
            );
            safeTransFrom.wait();

            owner = await NFT.ownerOf(VERSE_NODE)
            expect(owner).equal(fooAcc.address);
        });

        //
        //
        //

        // TODO Burning NFT (root, verse...)
        // TODO Reclaim Node
        // TODO expired transfer
        // TODO Lock/unLock Node, and transfer, burn

    });

});

