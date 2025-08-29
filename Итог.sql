--№1

select a.model, count(s.seat_no)
from aircrafts a 
join seats s using(aircraft_code)
group by a.aircraft_code
having count(s.seat_no) < 50

--№2

select date_trunc('month', book_date)::date as mount, sum(total_amount), 
	round((((sum(total_amount) - (lag(sum(total_amount)) over (order by date_trunc('month', book_date)::date))) 
		/ lag(sum(total_amount)) over (order by date_trunc('month', book_date)::date)) * 100), 2)
from bookings
group by mount

--№3

select a.model, array_agg(s.fare_conditions) as class
from aircrafts a 
join seats s using(aircraft_code)
group by a.aircraft_code
having not 'Business' = any (array_agg(s.fare_conditions))

--№4

select t.departure_airport, t.actual_departure, t.count, t.sum
from(
	select t.actual_departure, t.departure_airport, t.aircraft_code, s.count,
		   count(t.aircraft_code) over (partition by t.actual_departure, t.departure_airport) count_of_boards,
		   sum(s.count) over (partition by t.actual_departure, t.departure_airport rows between unbounded preceding and current row)
	from (
		select date_trunc('day', f.actual_departure) as actual_departure,
			 f.departure_airport,
			 f.aircraft_code
		from flights f
		left join boarding_passes bp on bp.flight_id = f.flight_id
		where bp.boarding_no is null and (f.status = 'Departed' or f.status = 'Arrived')
		group by 1,2,3) t
	left join (select aircraft_code, count(seat_no)
			   from seats s 
			   group by aircraft_code) s on s.aircraft_code = t.aircraft_code		
	order by 1,2) t 
where count_of_boards > 1	

--№5

select a.airport_name as vulet, a1.airport_name as prilet, count(flight_id)*100 / sum(count(flight_id)) over ()
from flights f 
join airports a on f.departure_airport = a.airport_code
join airports a1 on f.arrival_airport = a1.airport_code
group by a.airport_code, a1.airport_code

--№6

select substring(((contact_data ->> 'phone') :: text) from 3 for 3) as code, 
	count(substring(((contact_data ->> 'phone') :: text) from 3 for 3))
from tickets t 
group by code

--№7

select oborot, count(oborot)
from (select sum(tf.amount),
(select
	case
		when (sum(tf.amount) < 50000000) then 'low'
		when (sum(tf.amount) < 150000000) then 'middle'
		else 'high'
	end as oborot)
from flights f 
join ticket_flights tf using(flight_id)
group by f.departure_airport, f.arrival_airport) 
group by oborot

--№8

select Mbileta, Mbroni, round((Mbroni / Mbileta):: numeric, 2)
from 
	(select percentile_cont(0.5) within group (order by tf.amount) as Mbileta,
	percentile_cont(0.5) within group (order by b.total_amount) as Mbroni
from ticket_flights tf 
join tickets t using(ticket_no)
join bookings b using(book_ref))

--№9

create extension cube
create extension earthdistance

select f.departure_airport, f.arrival_airport, f.rast_km, f.cena, f.cena/f.rast_km, min(f.cena/f.rast_km) over()
from (select f.departure_airport, f.arrival_airport, min(f.cena) as cena,
		(earth_distance (ll_to_earth (a1.longitude, a1.latitude), ll_to_earth (a2.longitude, a2.latitude)):: int) / 1000 as rast_km
	from (select f.departure_airport, f.arrival_airport, min(tf.amount) as cena
		from flights f 
		join ticket_flights tf using(flight_id)
		group by f.departure_airport, f.arrival_airport) f
	join airports a1 on f.departure_airport = a1.airport_code
	join airports a2 on f.arrival_airport = a2.airport_code
	group by f.departure_airport, f.arrival_airport,  a1.airport_code, a2.airport_code) f


