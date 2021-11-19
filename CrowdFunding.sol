// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract CrowdFunding {
    // enum State { Opened, Closed }

    struct Contribution {
        address contributor;
        uint amount;
    }
    
    struct Project {
        string id;
        string name;
        address payable authorAddress;
        bool isFundable;
        uint targetAmount;
        uint amountFunded;
    }
    
    Project[] public projects;
    mapping( string => Contribution[]) public contributions;

    // Events
    event projectFunded(
        address sender,
        uint amount
    );
    
    event projectStateChanged (
        string projectName,
        string message
    );
    
    event projectCreated (
        string id,
        string name,
        uint targetAmount
    );
    // ./Events
    
    function createProject(string calldata _id, string calldata _projectName, uint _targetAmount) public {
        require(_targetAmount > 0, 'The funded amount must be greater than 0');
        Project memory project = Project(_id, _projectName, payable(msg.sender), true, _targetAmount, 0);
        projects.push(project);
        emit projectCreated(_id, _projectName, _targetAmount);
    }
    
    function fundProject(uint projectIndex) public payable isNotAuthor(projectIndex) canFund(projectIndex) {
        require(msg.value > 0, 'The funded amount must be greater than 0');
        Project memory project = projects[projectIndex];
        project.authorAddress.transfer(msg.value);
        project.amountFunded += msg.value;
        contributions[project.id].push(Contribution(msg.sender, msg.value));
        projects[projectIndex] = project;
        
        emit projectFunded(msg.sender, msg.value);
    }
    
    function changeProjectState(string calldata newState, uint projectIndex) public isAuthor(projectIndex) {
        string memory currentState = projects[projectIndex].isFundable ? string('opened') : string('closed');
        
        require(keccak256(abi.encode(newState)) == keccak256(abi.encode('opened')) || keccak256(abi.encode(newState)) == keccak256(abi.encode('closed')), 'This state is not defined');
        require(keccak256(abi.encode(newState)) != keccak256(abi.encode(currentState)), string(abi.encodePacked('This project is already ', currentState )));
        
        Project memory project = projects[projectIndex];
        if(keccak256(abi.encode(newState)) == keccak256(abi.encode('opened'))){
            project.isFundable = true;
        } else if(keccak256(abi.encode(newState)) == keccak256(abi.encode('closed'))) {
            project.isFundable = false;
        }
        
        emit projectStateChanged(project.name, project.isFundable ? 'Project opened' : 'Project closed');
    }
    
    
    // Function modifiers
    modifier isAuthor(uint projectIndex){
        require(projects[projectIndex].authorAddress == msg.sender, "You must be the project author!");
        _;
    }
     
    modifier isNotAuthor(uint projectIndex) {
        require(projects[projectIndex].authorAddress != msg.sender, "As author you can not fund your own project!");
        _;
    }
    
    modifier canFund(uint projectIndex){
        require(projects[projectIndex].isFundable == true, "This project is not available for funding!");
        _;
    }
    // ./Function modifiers
    
    function getGoal(uint projectIndex) public view returns(uint){
        return projects[projectIndex].targetAmount;
    }
    
    function getFunds(uint projectIndex) public view returns(uint){
        return projects[projectIndex].amountFunded;
    }
    
    function getStatus(uint projectIndex) public view returns(string memory){
        return projects[projectIndex].isFundable ? 'Opened': 'Closed';
    }
}