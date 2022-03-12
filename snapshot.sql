select
DISTINCT ON (no.address) address,
/*to_timestamp(timestamp / 1000) as timestamp,*/
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
order by no.address
;
