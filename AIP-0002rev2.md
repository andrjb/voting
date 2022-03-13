# voting.anetabtc.io
* AIP: 2
* Title: voting.anetabtc.io
* Authors: andrjb
* Status: Draft
* Type: Process
* Created: 2022-03-13
## Abstract
The idea of AIP-0002 is to specify and explore concrete ideas for a voting platform. Different approaches will be considered and their advantages and disadvantages weighed. The topic of decentralization will be addressed and specific examples of how such a protocol might operate will be discussed. 
## Motivation
After the introduction of AGPs and AIPs, the next important step is to provide the community with a platform to vote on them. Since anetaBTC functions as a DAO, every owner of cNETA or NETA tokens is entitled to have a say in the future of the protocol. Therefore, it is crucial to provide a fair and robust platform to make these votes and shape the future of the protocol. Verifiability and transparency are strengths of blockchain technology, which is a good underlying principle for building this voting platform. 
## Specification
### Basics
The basic principle of a voting session is simple. Every owner of cNETA or NETA is entitled to vote. However, the amount of tokens a person holds plays a role. The more a person owns, the heavier weighs their decision. Here we will discuss how a voting round could be carried out. In order for a voting session to occur, there needs to be AGPs or AIPs ready to vote on. If this is the case, a voting round is initiated according to the following procedure. 
* The voting session gets announced together with a specific date for the snapshot and the AGPs or AIPs that will be voted on
* At the earliest one week after the announcement a snapshot of all wallets holding cNETA or NETA is taken
* After the snapshot, the voting page will be up, which will provide a form for voting. The voters have 7 days to submit their vote
* Depending on the votes entered, the page will generate a characteristic number reflecting the choices. The voter can then create a transaction to themselve to register the vote on the blockchain (this can be done with a dapp in the future)

### Traceability
The idea is that the voting results can be verified by anyone and all steps are traceable. After the announcement and a long enough wait time, a snapshot of all wallets is taken. Everyone can reproduce this snapshot, since it will take place at a certain block height or at a certain time. These data will be used later to determine the weight of a vote. As already explained in "Basics" the voting results can also be verified by everyone since these are characteristic transactions, which are traceable on the blockchain. 
### Data acquisition
The most elegant way to acquire the desired data is to use a chain-grabber (Ergo) and a db-sync (Cardano). These programs both load all data of the blockchain into a Postgres database, which can be queried. 
#### Snapshot
The following query can be used to take a snapshot of all Ergo wallets that hold NETA. 
```diff
select
DISTINCT ON (no.address) address,
no.box_id,
SUM(neta_quantity) over (partition by no.address) as account_total,
a.token_id
from node_outputs no 

left join 
(select ni.box_id
  from node_inputs ni
where ni.main_chain = true ) i
on i.box_id = no.box_id

left join 
(select na.token_id, na.box_id, na.value/10^6 as neta_quantity
from node_assets na) a
on a.box_id = no.box_id

where no.main_chain = true
and a.token_id = '472c3d4ecaa08fb7392ff041ee2e6af75f4a558810a74b28600549d5392810e8'
and not exists (select box_id from node_inputs ni where no.box_id = ni.box_id)
and no.address like '9%%'
;
```
The output of the query will look similar to the following picture.

![image](https://user-images.githubusercontent.com/99014268/158035972-923610ee-b903-417c-a738-30c5e0b167c5.png)
#### Note
This query must be executed at the time of the snapshot (or the chain-grabber must be stopped at the right time), since the amount of NETA in possession may change afterwards. 

#### Collecting votes
Votes can be collected through the following query. 
```
select no.address,
qi.origaddress,
value,
no.tx_id,
settlement_height,
row_number() over (partition by no.address order by settlement_height desc) as rnk,
i.origbox,
kk.acctot
from public.node_outputs as no

left join 
(select ni.tx_id, ni.box_id as origbox
  from node_inputs ni
where ni.main_chain = true ) i
on i.tx_id = no.tx_id

left join 
(select uq.box_id, uq.address as origaddress
  from node_outputs uq
where uq.main_chain = true ) qi
on qi.box_id = i.origbox

left join 
(select ki.address, ki.account_total as acctot
  from test ki
where ki.address like '9%%') kk
on kk.address = no.address

where
(no.settlement_height between 694549 and 705885) 
and (no.value = 30042146 or no.value = 30053153)
and no.address like '9%%'
and no.address = qi.origaddress
order by no.tx_id, index
;
```
This query can be executed after closing the voting session to get the voting results. The range of the block height can be specified to fit the voting period. Furthermore, the value for all possibilities of characteristic transactions can be adjusted. This query already checks whether someone has tried to cast a vote for a wallet that does not belong to them and automatically ignores these transactions. There is also a column that shows which is the latest characteristic transaction. This allowes that if someone changes their mind during the voting session, a transaction can be made again and only the latest transaction will be taken into account. Currently older votes get saved too for additional traceability. The "test" table mentioned in the code is a snapshot of all wallets that have NETA. The snapshot must be imported as a table, which can then be used to directly output the corresponding amount of NETA to the voting results. The output of this query is a table that already contains all the information to determine the voting results. Now all that remains is for a script to count the votes. 

![image](https://user-images.githubusercontent.com/99014268/158069398-cf92b0d1-71bd-4272-90be-48db5d750840.png)
### Additional
#### Building a basic voting "hash"
Imagine that a voting session is ongoing with 3 proposals. The user can determine how to vote on each proposal and the website generates a transaction based on the decisions reflecting them. The following picture illustrates how a simple voting form could look like. 

![image](https://user-images.githubusercontent.com/99014268/158069879-6e90d485-8ed9-4351-9fa2-ef10fbbfba27.png)

In order to avoid interferences with voting sessions of other DAOs, which may use the same system, the value 012340 is added in front of the actual information (here 113) so that it is clear that this transaction belongs to an anetaBTC voting session.
#### Potential dapp
This approach could be made more user-friendly by building a simple dapp. Instead of having to do the transactions manually, the dapp can automatically build the transactions so that the user only has to sign the transaction. This means that the user only has to fill in his voting decisions, press a button and sign a automatically generated transaction which includes their decision. 
#### Discussions 
Traffic073 had the idea to do the voting with voting-tokens, which are distributed via an airdrop platform. These tokens are then collected in " ballot boxes". He described his idea with the following picture. 

![image](https://user-images.githubusercontent.com/99014268/158072680-171b0311-f7c3-4239-9f67-16805c3c8ac4.png)

##### Pro and contras
This idea seems user-friendly and is probably easier to understand than the voting transactions solution in its simplest implementation. However, voting tokens must be distributed at each voting round. This can be done via an airdrop, but this can lead to high costs especially on the Cardano side. Letting users claim the tokens would be another option but it seems to increase the inhibition to participate in the voting at all. Furthermore, this solution needs more transactions in total, as the voting transaction solution only requires one transaction to be signed by the user. It is nonetheless an interesting proposal that may also be pursued. 
## Conclusions
The approach described in this AIP can be used to implement a traceable, verifiable, and robust voting platform that pulls all data directly from the blockchain. The user interaction is kept as simple as possible, as the user only has to make one transaction to participate in the voting. The user experience could be further enhanced by creating a voting dapp that allows the user to simply enter their voting decisions into a form and then a transaction is automatically generated. 

**Credits to**: 

*https://github.com/Eeysirhc also known as curbsideprophet for providing a [query](https://github.com/Eeysirhc/ergo-intelligence/blob/main/sql/anetabtc-address_balance.sql) which needed only slight modifications to create a snapshot :blue_heart:*

*Pulsarz for pointing me in the right directions*

*Traffic073 for discussing the AIP with me and proposing other creative solutions*
