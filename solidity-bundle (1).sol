// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
interface IAavePool {
function flashLoanSimple(address receiver,address asset,uint256 amount,bytes calldata params,uint16 referralCode) external;
}
interface IFlashLoanSimpleReceiver {
function executeOperation(address asset,uint256 amount,uint256 premium,address initiator,bytes calldata params) external returns (bool);
}
interface IAerodromeRouter {
function addLiquidity(address tokenA,address tokenB,bool stable,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint liquidity,uint amountA,uint amountB);
}
interface IAerodromeFactory {
function getPair(address tokenA,address tokenB,bool stable) external view returns (address);
function createPair(address tokenA,address tokenB,bool stable) external returns (address);
}
interface IERC20 { function totalSupply() external view returns (uint256); function balanceOf(address) external view returns (uint256); function transfer(address,uint256) external returns (bool); function approve(address,uint256) external returns (bool); function transferFrom(address,address,uint256) external returns (bool); }
contract EUSD {
string public name; string public symbol; uint8 public decimals=18; uint256 public totalSupply;
mapping(address=>uint256) public balanceOf; mapping(address=>mapping(address=>uint256)) public allowance;
address public creator;
constructor(string memory _n,string memory _s,address _creator,uint256 _supply){
name=_n;symbol=_s;creator=_creator;
uint256 creatorMint=_supply*2/100; uint256 userMint=_supply-creatorMint;
_mint(_creator,creatorMint); _mint(msg.sender,userMint);
}
function approve(address s,uint256 a) external returns(bool){allowance[msg.sender][s]=a;return true}
function transfer(address to,uint256 a) external returns(bool){require(balanceOf[msg.sender]>=a,"bal");balanceOf[msg.sender]-=a;balanceOf[to]+=a;return true}
function transferFrom(address f,address to,uint256 a) external returns(bool){require(allowance[f][msg.sender]>=a,"allow");require(balanceOf[f]>=a,"bal");allowance[f][msg.sender]-=a;balanceOf[f]-=a;balanceOf[to]+=a;return true}
function _mint(address to,uint256 a) internal {totalSupply+=a;balanceOf[to]+=a}
}
contract Bootstrapper is IFlashLoanSimpleReceiver {
address public owner; IAavePool public pool; IAerodromeRouter public router; IAerodromeFactory public factory; IERC20 public usdc; EUSD public eusd; bool public stablePool;
event LiquidityAdded(uint liq,uint a,uint b); event FlashExecuted(uint amount,uint premium);
constructor(address _pool,address _router,address _factory,address _usdc,bool _stable){owner=msg.sender;pool=IAavePool(_pool);router=IAerodromeRouter(_router);factory=IAerodromeFactory(_factory);usdc=IERC20(_usdc);stablePool=_stable}
function setEUSD(address _eusd) external {require(msg.sender==owner,"owner");eusd=EUSD(_eusd);}
function ensurePair(address tokenA,address tokenB) public returns(address){
address p=factory.getPair(tokenA,tokenB,stablePool); if(p==address(0)){p=factory.createPair(tokenA,tokenB,stablePool);} return p;
}
function bootstrap(uint loanUSDC,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,uint deadline) external {
require(msg.sender==owner,"owner");
bytes memory params=abi.encode(amountADesired,amountBDesired,amountAMin,amountBMin,deadline);
pool.flashLoanSimple(address(this),address(usdc),loanUSDC,params,0);
}
function executeOperation(address asset,uint amount,uint premium,address,bytes calldata params) external override returns(bool){
require(msg.sender==address(pool),"pool"); require(asset==address(usdc),"asset");
(uint aDes,uint bDes,uint aMin,uint bMin,uint deadline)=abi.decode(params,(uint,uint,uint,uint,uint));
eusd.approve(address(router),aDes); usdc.approve(address(router),bDes);
(uint liq,uint a,uint b)=router.addLiquidity(address(eusd),address(usdc),stablePool,aDes,bDes,aMin,bMin,owner,deadline);
emit LiquidityAdded(liq,a,b); emit FlashExecuted(amount,premium);
usdc.approve(address(pool),amount+premium); return true;
}
}
contract StableForgeFactory {
event StableDeployed(address eusd,address bootstrapper);
address public owner; address public aavePool; address public aerodromeRouter; address public aerodromeFactory; address public usdc; address public creator;
constructor(address _pool,address _router,address _factory,address _usdc,address _creator){owner=msg.sender;aavePool=_pool;aerodromeRouter=_router;aerodromeFactory=_factory;usdc=_usdc;creator=_creator;}
function deployStable(string memory name,string memory symbol,uint supply,bool useFlash,uint loanUSDC,uint aDes,uint bDes,uint aMin,uint bMin,uint deadline) external returns(address,address){
EUSD token=new EUSD(name,symbol,creator,supply);
Bootstrapper boot=new Bootstrapper(aavePool,aerodromeRouter,aerodromeFactory,usdc,true);
boot.setEUSD(address(token)); boot.ensurePair(address(token),usdc);
if(useFlash){ boot.bootstrap(loanUSDC,aDes,bDes,aMin,bMin,deadline); }
emit StableDeployed(address(token),address(boot)); return (address(token),address(boot));
}
}}