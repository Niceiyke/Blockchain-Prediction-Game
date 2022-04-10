// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.11;

contract PredictionMarket {
  enum Choice { PDP, APC }
  struct Result {
    Choice winner;
    Choice loser;
  }
  Result result;
  bool gameFinished;
  bool pause;
  uint totalBets;
  uint fee;
 
  mapping(address =>uint) public wager; 
  mapping(Choice => uint) public bets;
  mapping(address => mapping(Choice => uint)) public betsPerPlayer;
  address public oracle;
  address public bookie;

  constructor(address _oracle, address _bookie) {
    oracle = _oracle; 
    bookie = _bookie;
  }

  function placeBet(Choice _side) external payable {
    require(gameFinished == false, 'game is finished');
    bets[_side] += msg.value;
    betsPerPlayer[msg.sender][_side] += msg.value;
    totalBets +=msg.value;
    wager[msg.sender] +=msg.value;
  }

  function withdrawGain() external {
    uint playersBet = betsPerPlayer[msg.sender][result.winner];
    require(playersBet > 0, 'you do not have any winning bet');  
    require(gameFinished == true, 'game not finished yet');
    uint gain = playersBet + bets[result.loser] * (playersBet / bets[result.winner])*fee;
    betsPerPlayer[msg.sender][Choice.PDP] = 0;
    betsPerPlayer[msg.sender][Choice.APC] = 0;
    totalBets -= gain;
    payable(msg.sender).transfer(gain);
  }

    function withdrawStake() external { 
    require (pause ==true, 'prediction is not in paused mode');
    require(wager[msg.sender]!=0, 'you do not have any active wager');
    require(block.timestamp > block.timestamp + 1 days, 'waiting period has not elapsed');
    uint stake =wager[msg.sender];
    wager[msg.sender]=0;
    totalBets-=stake;
    payable(msg.sender).transfer(stake);
  }

  function reportResult(Choice _winner, Choice _loser) external {
    require(oracle == msg.sender, 'only oracle');
    result.winner = _winner;
    result.loser = _loser;
    gameFinished = true;
  }

  function pausePrediction()external{
  require(msg.sender==bookie, 'Your not the bookie');
  pause= true;
  }

  function unPausePrediction()external{
  require(msg.sender==bookie, 'Your not the bookie');
  pause= false;
  }
  
}