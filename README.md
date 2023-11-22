Check the Virgin Atlantic 'seat-checker-api' for available upgrades for a given route and date.
Useful if you want to use your points to upgrade an eligable flight.

### Usage
```shell
$ ./virgin.sh
Get premium seat upgrade availability on Virgin Atlantic flights
Usage: $0 <FROM> <TO> YYYY-MM-DD
eg   : $0 SEA    LHR  2023-11-18
```

### Example - lack of availability
```shell
$ ~/src/virgin.sh LHR SEA 2023-11-23
[+] Checking Virgin reward-seat-checker-api for LHR -> SEA on 2023-11-23
[+] Get session cookie...
[+] Get availability...
{
  "date": "2023-11-23",
  "min_price": null,
  "min_points": 0,
  "economy_seats": null,
  "premium_seats": null,
  "business_seats": null
}
[!] No premium seats available
```

### Example - available upgrade and link to 'chat to agent' for upgrade with points.
```shell
$ ~/src/virgin.sh LHR SEA 2024-03-01
[+] Checking Virgin reward-seat-checker-api for LHR -> SEA on 2024-03-01
[+] Get session cookie...
[+] Get availability...
{
  "date": "2024-03-01",
  "min_price": 390.89,
  "min_points": 27500,
  "economy_seats": 9,
  "premium_seats": 9,
  "business_seats": 0
}
[*] Premium seats available, chat for upgrade : https://www.virginatlantic.com/mytrips/findPnr.action
```
