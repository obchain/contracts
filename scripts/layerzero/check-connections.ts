import hre, { ethers } from "hardhat";

import connections from "./connections";
import { zeroPadValue } from "ethers";

const main = async function () {
  console.log("network", hre.network.name);
  const connection = connections.find((c) => c.network === hre.network.name);

  console.log("connection", connection);

  if (!connection) throw new Error("cannot find connection");
  const oft = await ethers.getContractAt("OFT", connection.oft);
  const endpoint = await ethers.getContractAt(
    "IL0EndpointV2",
    await oft.endpoint()
  );

  const remoteConnections = connections.filter(
    (c) => c.network !== hre.network.name
  );

  const owner = await oft.owner();
  const delegate = await endpoint.delegates(oft.target);

  console.log("owner", owner);
  console.log("delegate", delegate);
  console.log("valid", delegate.toLowerCase() == owner.toLowerCase());

  for (let index = 0; index < remoteConnections.length; index++) {
    const remote = remoteConnections[index];

    const remoteOft = zeroPadValue(remote.oft, 32);
    console.log("\nnetwork", remote.network);
    console.log("remote peer", remoteOft);

    const peer = await oft.peers(remote.peerId);
    console.log("received peer", peer);
    console.log("valid", peer.toLowerCase() == remoteOft.toLowerCase());

    if (peer.toLowerCase() != remoteOft.toLowerCase()) {
      const data = await oft.setPeer.populateTransaction(
        remote.peerId,
        remoteOft
      );
      console.log("use to", data.to);
      console.log("use data", data.data);
    }
  }
};

main();
