# voting.anetabtc.io
* AIP: 2
* Title: voting.anetabtc.io
* Authors: andrjb
* Status: Draft
* Type: Process
* Created: 2022-03-12
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
* Depending on the votes entered, the page will generate a characteristic number reflecting the choices. The voter can then create a transaction to themselve to register the vote on the blockchain (this can be done later with a dapp)

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
This query must be executed at the time of the snapshot, since the amount of NETA in possession may change afterwards. 

**Credits to**: *https://github.com/Eeysirhc also known as curbsideprophet for providing a [query](https://github.com/Eeysirhc/ergo-intelligence/blob/main/sql/anetabtc-address_balance.sql) which needed only slight modifications :blue_heart:*
