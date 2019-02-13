describe("Videos", function() {
    let near;
    let contract;
    let alice;
    let bob = "bob.near";
    let eve = "eve.near";
  
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 10000;

    beforeAll(async function() {
      const config = await nearlib.dev.getConfig();
      near = await nearlib.dev.connect();
      alice = nearlib.dev.myAccountId;
      const url = new URL(window.location.href);
      config.contractName = url.searchParams.get("contractName");
      console.log("nearConfig", config);
      contract = await near.loadContract(config.contractName, {
        // NOTE: This configuration only needed while NEAR is still in development
        viewMethods: ["getLastVideos"],
        changeMethods: ["postVideo"],
        sender: alice
      });
    });

  
    it("can be stored on chain", async function() {
      await contract.postVideo({ hash: "whatever" });

      const videos = await contract.getLastVideos();
      expect(videos).toEqual(["whatever"]);
    });
  });