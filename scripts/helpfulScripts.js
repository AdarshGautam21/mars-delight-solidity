const pinataSDK = require("@pinata/sdk");
require('dotenv').config();
const fs = require('fs');


const pinata = pinataSDK(process.env.Pinata_key, process.env.Pinata_Secret_key);
const readableStreamOfFile = fs.createReadStream("./images/MENU(1).png");

const options = {
    pinataMetaData: {
        name: MyCustomName,
        keyvalues: {
            customKey : "customValue",
            customKey2 : "customValue2"
        }
    },
    pinataOptions: {
        cidVersion : 0
    }
};

const pinFileToIPFS = () => {
    pinata.pinFileToIPFS(readableStreamOfFile,options).then((result)=>{
        return 'https://gateway.pinata.cloud/ipfs/${result.IpfsHash}'
    }).catch((err)=> {
        console.log(err)
    })
}