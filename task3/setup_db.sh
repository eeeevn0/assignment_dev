#!/bin/bash

# Configurarea containerului
CONTAINER_NAME="postgres-company"  # numele containerului postgresql
DB="company_db"                    # numele bazei de date
USER="ituser"                      # utilizatorul principal
PASSWORD="passwordituser"         # parola pentru utilizator (necesară la crearea containerului)
ADMIN_USER="admin_cee"             # numele utilizatorului admin secundar
ADMIN_PASS="adminpass"             # parola pentru utilizatorul admin
HOST_SQL_PATH="/Users/eugeniavacarciuc/Downloads/assignment/populatedb.sql" # calea către fișierul SQL pe sistemul gazdă
CONTAINER_SQL_PATH="/tmp/populatedb.sql"  # calea unde va fi copiat fișierul în container

# verificam mai intai dacă containerul exista si rulează
if [ ! "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=$CONTAINER_NAME)" ]; then
        #curatam daca containerul exista dar este oprit
        echo "Containerul există dar este oprit. Îl ștergem..."
        docker rm $CONTAINER_NAME
    fi
    
    #cream și pornim containerul
    echo "Creăm containerul PostgreSQL..."
    docker run --name $CONTAINER_NAME \
        -e POSTGRES_USER=$USER \
        -e POSTGRES_PASSWORD=$PASSWORD \
        -e POSTGRES_DB=postgres \
        -v pgdata:/var/lib/postgresql/data \  # volum pentru persistenta datelor
        -p 5432:5432 \
        -d postgres:15
    
    # așteptam ca PostgreSQL sa porneasca complet
    echo "Așteptăm pornirea PostgreSQL..."
    sleep 10
fi

#copiem fisierul SQL în container
docker cp $HOST_SQL_PATH $CONTAINER_NAME:$CONTAINER_SQL_PATH

# cream baza de date
docker exec $CONTAINER_NAME psql -U $USER -d postgres -c "DROP DATABASE IF EXISTS $DB;"
docker exec $CONTAINER_NAME psql -U $USER -d postgres -c "CREATE DATABASE $DB;"

#cream utilizatorul admin dacă nu exista
docker exec $CONTAINER_NAME psql -U $USER -d postgres -c "
DO \$\$ 
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$ADMIN_USER') THEN
     CREATE ROLE $ADMIN_USER WITH LOGIN SUPERUSER PASSWORD '$ADMIN_PASS';
   END IF;
END \$\$;"

#acordam privilegii
docker exec $CONTAINER_NAME psql -U $USER -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB TO $ADMIN_USER;"

#importam setul de date
docker exec $CONTAINER_NAME psql -U $USER -d $DB -f $CONTAINER_SQL_PATH

#cream fișierul queries.sql cu interogările necesare
cat > ./queries.sql << 'EOF'
-- Interogarea 1: numarul total de angajați
SELECT COUNT(*) AS numar_total_angajati FROM employees;

-- Interogarea 2: numele angajatilor dintr-un departament specific(luam IT ca exemplu)  
-- Notă: Poți modifica această interogare pentru a folosi un alt departament
SELECT e.first_name AS prenume, e.last_name AS nume
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'IT';

-- Interogarea 3: salariile maxime si minime per departament
SELECT d.department_name AS departament,
       MAX(s.salary) AS salariu_maxim,
       MIN(s.salary) AS salariu_minim
FROM departments d
JOIN employees e ON d.department_id = e.department_id
JOIN salaries s ON e.employee_id = s.employee_id
GROUP BY d.department_name
ORDER BY d.department_name;
EOF

#copiem fisierul de interogsri în container
docker cp ./queries.sql $CONTAINER_NAME:/tmp/queries.sql

#executăm interogarile si salvam rezultatele in fisierul de log
docker exec $CONTAINER_NAME bash -c "psql -U $USER -d $DB -f /tmp/queries.sql > /tmp/query_results.log"

#copiem fisierul de log din container pe sistemul gazda"
docker cp $CONTAINER_NAME:/tmp/query_results.log ./query_results.log

echo "Procesul s-a finalizat. Rezultatele au fost salvate în ./query_results.log"
