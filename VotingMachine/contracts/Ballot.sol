// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';//This will inherit the (well established and well tested community driven)ERC721 contract.

    //Since this contract inherits all the functions from ERC721, to easily differentiate i used UPPERCASE lettes for the function names in the Ballot contract.


contract Ballot is ERC721{
   
    struct Voter {
        uint weight; 
        bool voted;  
        address delegate; 
        uint vote;  
        uint NoOfNfts;// Number of nfts a wallet holds
    }

    struct Proposal {
        
        bytes32 name;   
        uint voteCount; 
    }
    
     uint public tokenId=0;// will keep track of the Nft supply

    bool public VotingStopped=false;//will trigger the voting to be stopped

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

  
    constructor(bytes32[] memory proposalNames) ERC721("VoteCertificate","Voted") {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalNames.length; i++) {
            
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
    function CHANGECHARIMAN(address _newChairPerson) public  {          //this is a function which change the chairperson to another person
        require(msg.sender == chairperson,"Only the chairperson can access this functionality ");
        require(VotingStopped==false,"This function cannot be accesed if the voting has ended"); //this will make sure that the chairperson cannot give his role after voting has ended.
        chairperson = _newChairPerson;
        voters[_newChairPerson].weight=1;
        
    }
     function CLAMNFT() public  {         //i have created a new function that will give NFT to the voters which can be used as a voting cirtificate.
        require(voters[msg.sender].voted == true," you need to vote to receive this NFT ");   //this error function will make sure that people who only vote receive will receive the NFt
        require(voters[msg.sender].NoOfNfts==0,"you allready received your nft or you are not Elgible to receive an NFT since you deligated your vote");    //this function will make sure that each person will receive a single NFT.
        require(VotingStopped==true,"Voting has not ended");     // wallets can clam nfts only when voting stops.
        voters[msg.sender].NoOfNfts=1;
        tokenId++;      //will add one to the current supply when ever the function is Called
        uint tokensupply=tokenId;     // i have assigned the state variable to a local one to save some gas.
        _safeMint(msg.sender,tokensupply);
        //_setTokenURI(tokensupply, "ipfs://QmZ29R8s98BaurZEnmAyXannJ4gSeGksWo4QnHwyy1JzLK.json");// tried to add ipfs url but couldnot succeed. 
        

    }
    
 
    function GIVERIGHTTOVOTE(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0,"The voter allready has the the Right to vote."); // added an error message
        voters[voter].weight = 1;
    }

 
    function DELEGATE(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");
        
         voters[msg.sender].NoOfNfts=1;    //this will not allow a wallet to clam nft since they deligated their vote, To call the CLAMNFT function the the value of NoOfNfts mapped to an address should be equal to 0.
        // I added this functionality to encourage wallet addresses not to deligate their vote to other wallets since this would create a biased result.

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            
            delegate_.weight += sender.weight;
        }
    }

  
    function CASTVOTE(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        require(VotingStopped==false,"The Voting Has ended");  //This will make sure that the function will not be accessible once the voting has stopped.
        sender.voted = true;
        sender.vote = proposal;

       
        proposals[proposal].voteCount += sender.weight;
    }

  
    function WINNINGPROPOSAL() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }
    
     function STOPVOTING() public {   // When this function is called the vote function will not excute.
        require(msg.sender==chairperson,"only the chair person can call this function");   //Only the chairerson can stop the voting.
        VotingStopped=true; 
    }

   
    function WINNERNAME() public view returns (bytes32 winnerName_){
    
    require(VotingStopped==true,"Voting has not ended");//will throw an error if the the voting is still in progress.
        winnerName_ = proposals[WINNINGPROPOSAL()].name;
    }
}
