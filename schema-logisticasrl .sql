
DROP SCHEMA IF EXISTS logisticasrl;
CREATE SCHEMA logisticasrl;
USE logisticasrl;


CREATE TABLE utenti
	(
		username VARCHAR(45) PRIMARY KEY,
		password CHAR(32) NOT NULL,
		ruolo ENUM("amministratore", "cliente", "centro", "veicolo") NOT NULL
	);


CREATE TABLE cliente 
	(
		cf CHAR(16) PRIMARY KEY,
		nome VARCHAR(45) NOT NULL,
		cognome VARCHAR(45) NOT NULL,
		data_di_nascita DATE NOT NULL,
		via_residenza VARCHAR(90) NOT NULL,
		città_residenza VARCHAR(45) NOT NULL,
		cap_residenza INT UNSIGNED NOT NULL, 
		provincia_residenza VARCHAR(45) NOT NULL,
		via_fatturazione VARCHAR(90) NOT NULL,
		città_fatturazione VARCHAR(45) NOT NULL,
		cap_fatturazione INT UNSIGNED NOT NULL,
		provincia_fatturazione VARCHAR(45) NOT NULL,
		username VARCHAR(45) UNIQUE NOT NULL,
		FOREIGN KEY (username) REFERENCES utenti(username)
	);


CREATE TABLE carta_di_credito
	(
		numero BIGINT UNSIGNED PRIMARY KEY,
		nome VARCHAR(45) NOT NULL,
		cognome VARCHAR(45) NOT NULL,
		data_di_scadenza DATE NOT NULL,
		codice_cvv SMALLINT UNSIGNED NOT NULL,
		cliente_titolare CHAR(16) UNIQUE NOT NULL,
		FOREIGN KEY (cliente_titolare) REFERENCES cliente(cf)
	);



CREATE TABLE recapiti
	(
		cellulare INT UNSIGNED PRIMARY KEY,
		telefono INT UNSIGNED NOT NULL UNIQUE,
		email VARCHAR(60) NOT NULL UNIQUE,
		cf_cliente CHAR(16) UNIQUE NOT NULL,
		FOREIGN KEY (cf_cliente) REFERENCES cliente(cf) 
	);


CREATE TABLE coordinate_cliente
	(
		cf_cliente CHAR(16) PRIMARY KEY,
		latitudine_cgr FLOAT NOT NULL,
		longitudine_cgr FLOAT NOT NULL,
		FOREIGN KEY (cf_cliente) REFERENCES cliente(cf)
	);


CREATE TABLE destinatario
	(
		latitudine FLOAT,
		longitudine FLOAT,
		nome VARCHAR(45) NOT NULL,
		cognome VARCHAR(45) NOT NULL,
		nazione VARCHAR(45) NOT NULL,
		PRIMARY KEY (latitudine, longitudine, nome, cognome)
	);



CREATE TABLE spedizione
	(
		codice_spedizione INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
		tipo_spedizione VARCHAR(45) DEFAULT NULL,
		cf_cliente CHAR(16) NOT NULL,
		latitudine_des FLOAT NOT NULL,
		longitudine_des FLOAT NOT NULL,
		FOREIGN KEY (latitudine_des, longitudine_des) REFERENCES destinatario(latitudine, longitudine),
		FOREIGN KEY (cf_cliente) REFERENCES cliente(cf)
	);


CREATE TABLE pacco
	(
		codice_sp INT UNSIGNED PRIMARY KEY,
		peso SMALLINT unsigned NOT NULL,
		lunghezza SMALLINT unsigned NOT NULL,
		larghezza SMALLINT unsigned NOT NULL,
		profondità SMALLINT unsigned NOT NULL,
		nome_categoria VARCHAR(45) DEFAULT NULL,
		FOREIGN KEY (codice_sp) REFERENCES spedizione(codice_spedizione)
	);


CREATE TABLE categoria
	(
		nome VARCHAR(45) PRIMARY KEY,
		prezzo_base FLOAT UNSIGNED NOT NULL,
		dimensione_minima FLOAT NOT NULL,
		dimensione_massima FLOAT NOT NULL
	);


CREATE TABLE fase
	(
		data_ora TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		codice_sp INT UNSIGNED,
		nome VARCHAR(45) NOT NULL,
		PRIMARY KEY (data_ora, codice_sp, nome),
		FOREIGN KEY (codice_sp) REFERENCES spedizione(codice_spedizione)
	);


CREATE TABLE centro_operativo
	(
		codice_co INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
		via VARCHAR(90) NOT NULL,
		città VARCHAR(45) NOT NULL,
		cap INT UNSIGNED NOT NULL,
		provincia VARCHAR(45) NOT NULL,
		recapito_telefonico INT UNSIGNED NOT NULL UNIQUE,
		latitudine FLOAT NOT NULL,
		longitudine FLOAT NOT NULL,
		nome_responsabile VARCHAR(45) NOT NULL,
		email_segreteria VARCHAR(60) NOT NULL UNIQUE,
		tipo_co VARCHAR(45) NOT NULL

	);


CREATE TABLE affidata_a
	(
		codice_sp INT UNSIGNED,
		codice_co INT UNSIGNED,
		ordine_spedizione INT UNSIGNED,
		PRIMARY KEY (codice_sp, codice_co),
		FOREIGN KEY (codice_sp) REFERENCES spedizione(codice_spedizione),
		FOREIGN KEY (codice_co) REFERENCES centro_operativo(codice_co)
	);


CREATE TABLE pagamento
	(	
		codice_sp INT UNSIGNED PRIMARY KEY,
		codice_co INT UNSIGNED,
		numero_carta BIGINT UNSIGNED,
		costo_effettivo FLOAT UNSIGNED NOT NULL,
		FOREIGN KEY (codice_co) REFERENCES centro_operativo(codice_co),
		FOREIGN KEY (numero_carta) REFERENCES carta_di_credito(numero),
		FOREIGN KEY (codice_sp) REFERENCES spedizione(codice_spedizione)

	);


CREATE TABLE veicolo
	(
		codice_v INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
		targa CHAR(7) NOT NULL UNIQUE,
		valore_volumetrico FLOAT NOT NULL,
		tipo_veicolo VARCHAR(45) NOT NULL,
		latitudine FLOAT NOT NULL,
		longitudine FLOAT NOT NULL
	);


CREATE TABLE possiede
	(
		codice_co INT UNSIGNED,
		codice_v INT UNSIGNED,
		PRIMARY KEY (codice_co, codice_v),
		FOREIGN KEY (codice_co) REFERENCES centro_operativo(codice_co),
		FOREIGN KEY (codice_v) REFERENCES veicolo(codice_v)
	);



CREATE TABLE assegnamento
	(
		codice_v INT UNSIGNED,
		codice_sp INT UNSIGNED,
		PRIMARY KEY (codice_sp),
		FOREIGN KEY (codice_v) REFERENCES veicolo(codice_v),
		FOREIGN KEY (codice_sp) REFERENCES spedizione(codice_spedizione)
	);


CREATE TABLE giacenza_pacchi_co
	(
		codice_co INT UNSIGNED,
		codice_sp INT UNSIGNED,
		PRIMARY KEY (codice_co, codice_sp),
		FOREIGN KEY (codice_co) REFERENCES centro_operativo(codice_co),
		FOREIGN KEY (codice_sp) REFERENCES spedizione(codice_spedizione)
	);


CREATE TABLE riassegnazione_veicolo
	(
		codice_sp INT, 
		codice_co INT, 
		tipo VARCHAR(45),
		PRIMARY KEY (codice_sp, codice_co)
	);




-- functions

DELIMITER //

CREATE FUNCTION distanza(lat1 FLOAT, long1 FLOAT, lat2 FLOAT, long2 FLOAT)
returns FLOAT
DETERMINISTIC
BEGIN
	DECLARE r INT;
	DECLARE dist FLOAT;
	SET lat1 = RADIANS(lat1);
	SET long1 = RADIANS(long1);
	SET lat2 = RADIANS(lat2);
	SET long2 = RADIANS(long2);
	SET r = 6371;
	SET dist = 2*r* asin( sqrt( POWER(sin((lat2-lat1)/2),2) + cos(lat1) *cos(lat2) *POWER(sin((long2-long1)/2),2) ) );
	return dist;
END //

DELIMITER ;









-- triggers

DELIMITER //
CREATE TRIGGER controllo_email_recapiti 
	BEFORE INSERT ON recapiti FOR EACH ROW
	BEGIN 
		IF NOT new.email regexp '^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9._-]@[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9]\\.[a-zA-Z]{2,63}$' THEN
			SIGNAL SQLSTATE '45000';
		END IF;
	END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER controllo_email_centro
	BEFORE INSERT ON centro_operativo FOR EACH ROW
	BEGIN 
		IF NOT new.email_segreteria regexp '^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9._-]@[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9]\\.[a-zA-Z]{2,63}$' THEN
			SIGNAL SQLSTATE '45000';
		END IF;
	END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER controllo_targa
	BEFORE INSERT ON veicolo FOR EACH ROW
	BEGIN
		IF NOT new.targa regexp '^[A-Za-z]{2}[0-9]{3}[A-Za-z]{2}$' THEN
			SIGNAL SQLSTATE '45000';
		END IF;
	END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER controllo_cf
	BEFORE INSERT ON cliente FOR EACH ROW
	BEGIN
		IF NOT new.cf regexp '^[A-Z]{6,6}[0-9]{2,2}[A-Z][0-9]{2,2}[A-Z][0-9]{3,3}[A-Z]$' THEN
			SIGNAL SQLSTATE '45000';
		END IF;
	END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER imposta_categoria_pacco
	BEFORE INSERT ON pacco FOR EACH ROW
    BEGIN
	DECLARE done int DEFAULT FALSE;
	DECLARE var_nome VARCHAR(45);
	DECLARE dim_min FLOAT;
	DECLARE dim_max FLOAT;
	DECLARE somma FLOAT;
	DECLARE cursore1 CURSOR FOR SELECT nome FROM categoria;
    DECLARE cursore2 CURSOR FOR SELECT dimensione_minima FROM categoria;
    DECLARE cursore3 CURSOR FOR SELECT dimensione_massima FROM categoria;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    SET somma = new.larghezza + new.lunghezza + new.profondità;
	open cursore1;
    open cursore2;
    open cursore3;
	read_loop: loop
		fetch cursore1 into var_nome;
        fetch cursore2 into dim_min;
        fetch cursore3 into dim_max;
		IF (somma > dim_min AND somma < dim_max) then
			SET new.nome_categoria = var_nome;
			LEAVE read_loop;
		ELSEIF done THEN 
			LEAVE read_loop;
		end if;
	end loop;
	close cursore1; 
    close cursore2;
    close cursore3;
end //
DELIMITER ;



DELIMITER //
CREATE TRIGGER assegnamento_veicolo
	BEFORE INSERT ON assegnamento FOR EACH ROW
	BEGIN
	DECLARE num INT;
	SELECT count(*) FROM assegnamento WHERE codice_sp = new.codice_sp INTO num;
	IF (num >= 1) THEN
		SIGNAL SQLSTATE "45000";
	END IF;
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER scadenza_carta_di_credito
	BEFORE INSERT ON carta_di_credito FOR EACH ROW
	BEGIN
	IF ( CURRENT_TIMESTAMP > new.data_di_scadenza) THEN
		SIGNAL SQLSTATE "45000";
	END IF;
END //
DELIMITER ;



DELIMITER //

CREATE TRIGGER verifica_tipo_spedizione
BEFORE INSERT ON spedizione FOR EACH ROW
BEGIN
	DECLARE nazione_des VARCHAR(45);
	SELECT nazione
	FROM destinatario
	WHERE new.latitudine_des = latitudine AND new.longitudine_des  = longitudine INTO nazione_des;

	IF (nazione_des = "italia") THEN
		SET new.tipo_spedizione = "nazionale";
	ELSE 
		SET new.tipo_spedizione = "internazionale";
	END IF;
END //

DELIMITER ;


DELIMITER //
CREATE TRIGGER inserimento_indirizzo_fatturazione
	BEFORE INSERT ON cliente FOR EACH ROW
	BEGIN
	IF (new.via_fatturazione = "" OR new.città_fatturazione = "" OR new.cap_fatturazione = 0
		OR new.provincia_fatturazione = "") THEN
		SET new.via_fatturazione = new.via_residenza;
		SET new.città_fatturazione = new.città_residenza;
		SET new.cap_fatturazione = new.cap_residenza;
		SET new.provincia_fatturazione = new.provincia_residenza;
	END IF;
END //
DELIMITER ;






/*funzione che passati in input latitudine e longitudine di 2 posti
restituisce la distanza tra i 2 punti*/





	



-- views

CREATE VIEW spazio_disponibile_veicolo (codice_veicolo, spazio_disponibile) AS
SELECT veicolo.codice_v, valore_volumetrico-COALESCE(sum(lunghezza*larghezza*profondità),0)
FROM veicolo LEFT join assegnamento on veicolo.codice_v = assegnamento.codice_v
	LEFT join pacco on assegnamento.codice_sp = pacco.codice_sp
GROUP BY veicolo.codice_v;


CREATE VIEW costo_spedizione (codice_spedizione, stima_costo, costo_effettivo) AS 
SELECT pacco.codice_sp, prezzo_base*peso, costo_effettivo
FROM pacco JOIN categoria ON nome = nome_categoria
	LEFT JOIN pagamento ON pagamento.codice_sp = pacco.codice_sp;



CREATE VIEW posizione_pacco (codice_spedizione, latitudine, longitudine) AS
SELECT pacco.codice_sp, latitudine, longitudine
FROM pacco JOIN assegnamento on assegnamento.codice_sp = pacco.codice_sp
	 JOIN veicolo ON veicolo.codice_v = assegnamento.codice_v
WHERE pacco.codice_sp = assegnamento.codice_sp;


CREATE VIEW spedizioni_accettate_24H (sp_accettate) AS
SELECT count(*)
FROM fase
where nome = "accettata" AND data_ora > (NOW() - interval 1 day);


CREATE VIEW spedizioni_consegnate_24H (sp_consegnate, entrate_totali) AS
SELECT count(*), sum(costo_effettivo)
FROM fase JOIN costo_spedizione ON codice_sp = codice_spedizione
WHERE nome = "consegnato" AND data_ora > (NOW() - interval 1 day);


CREATE VIEW coordinata_ritiro_pacco_cliente (cf_cl, latitudine_cl, longitudine_cl) AS
SELECT cf, latitudine_cgr, longitudine_cgr
FROM cliente JOIN coordinate_cliente as cc ON cc.cf_cliente = cf;




-- procedures



DELIMITER //
CREATE PROCEDURE inserimento_giacenza_pacchi_co (IN var_codice_co INT, IN var_codice_sp INT)
BEGIN
	DECLARE done INT DEFAULT FALSE;
	DECLARE cod_v INT;
	DECLARE spaz_disp FLOAT;
	DECLARE num_ord INT;
	DECLARE count INT;
	-- cursore che scorre tutti i furgoni appartenenti ad un centro operativo
	DECLARE cursore1 CURSOR FOR SELECT v.codice_v FROM possiede AS p JOIN veicolo as v ON p.codice_v = v.codice_v
							    WHERE codice_co = var_codice_co and tipo_veicolo = "furgone";
	-- cursore che scorre tutti i veicoli appartenenti ad un centro operativo
	DECLARE cursore2 CURSOR FOR SELECT v.codice_v FROM possiede AS p JOIN veicolo as v ON p.codice_v = v.codice_v
							    WHERE codice_co = var_codice_co;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;


	DECLARE exit HANDLER FOR SQLEXCEPTION
	BEGIN	
		ROLLBACK;
		RESIGNAL;
	END;

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	START TRANSACTION;

	-- inserimento del pacco all'interno di giacenza_pacchi_co
	INSERT INTO giacenza_pacchi_co VALUES (var_codice_co, var_codice_sp);

	-- quando un pacco arriva in un nuovo centro operativo viene scansionato il codice di spedizione
	-- e inserito all'interno di "giacenza_pacchi_co"
	-- all'arrivo del nuovo veicolo viene eliminato l'assegnamento tra il pacco consegnato al nuovo
	-- centro operativo ed il veicolo che lo trasportava
	DELETE FROM assegnamento WHERE codice_sp = var_codice_sp;
	-- viene aggiornata la fase della spedizione
	INSERT INTO fase VALUES (CURRENT_TIMESTAMP, var_codice_sp, CONCAT("raggiunto centro operativo ", var_codice_co));
	SELECT ordine_spedizione FROM affidata_a WHERE codice_co = var_codice_co AND codice_sp = var_codice_sp INTO num_ord;
	SET num_ord = num_ord + 1;
	SELECT count(*) FROM affidata_a WHERE codice_sp = var_codice_sp AND ordine_spedizione = num_ord INTO count;
	-- controllo se il centro operativo è l'ultimo nella lista degli affidamenti (non c'è nessun centro operativo dopo
	-- di lui). in questo caso il centro operativo è addetto alla consegna del pacco al destinatario
	IF ( count = 0)  THEN
		-- verifica se esiste un veicolo appartenente al centro operativo con abbastanza spazio disponibile per il pacco
		open cursore1;
		read_loop2: loop
			fetch cursore1 INTO cod_v;
			(SELECT spazio_disponibile FROM spazio_disponibile_veicolo WHERE codice_veicolo = cod_v) INTO spaz_disp;
			IF (spaz_disp > (SELECT lunghezza*larghezza*profondità FROM pacco WHERE codice_sp = var_codice_sp)) THEN
				-- se esiste un veicolo con spazio disponibile inserisce il seguente assegnamento
				INSERT INTO assegnamento VALUES (cod_v, var_codice_sp);
				DO SLEEP(1);
				INSERT INTO fase VALUES (CURRENT_TIMESTAMP, var_codice_sp, "in consegna");
				DO SLEEP(1);
				INSERT INTO fase VALUES (CURRENT_TIMESTAMP, var_codice_sp, "consegnato");
				DELETE FROM assegnamento WHERE codice_sp = var_codice_sp;
				LEAVE read_loop2;
			ELSEIF done THEN
				-- se non esiste il veicolo aggiorna la fase del pacco in "in attesa di recupero"
				DO SLEEP(1);
				INSERT INTO fase VALUES (CURRENT_TIMESTAMP, var_codice_sp, CONCAT("in attesa di smistamento presso ", var_codice_co));
				INSERT INTO riassegnazione_veicolo VALUES (var_codice_co, var_codice_sp, "smistamento");
				LEAVE read_loop2;
			END IF;
		END loop;
		close cursore1;
	
	-- altrimenti viene assegnato un nuovo veicolo per la spedizione verso un altro centro
	ELSE	 
		open cursore2;
		read_loop3: loop 
			fetch cursore2 INTO cod_v;
			(SELECT spazio_disponibile FROM spazio_disponibile_veicolo WHERE codice_veicolo = cod_v) INTO spaz_disp;
			IF (spaz_disp > (SELECT lunghezza*larghezza*profondità FROM pacco WHERE codice_sp = var_codice_sp)) THEN
				INSERT INTO assegnamento VALUES (cod_v, var_codice_sp);
				DO SLEEP(1);
				INSERT INTO fase VALUES (CURRENT_TIMESTAMP, var_codice_sp, "in transito");
				LEAVE read_loop3;
			ELSEIF done THEN
				-- se non esiste il veicolo aggiorna la fase del pacco in "attesa di smistamento presso XXX"
				INSERT INTO fase VALUES (CURRENT_TIMESTAMP, var_codice_sp, CONCAT("in attesa di smistamento presso ", var_codice_co));
				INSERT INTO riassegnazione_veicolo VALUES (var_codice_co, var_codice_sp, "smistamento");
				LEAVE read_loop3;
			END IF;
		END loop;
		close cursore2;

	END IF;

	COMMIT;
END //
DELIMITER ;



DELIMITER //
CREATE PROCEDURE start_ritiro_pacco(IN cod_sp INT, IN cod_co INT)
BEGIN
	DECLARE done INT DEFAULT FALSE;
	DECLARE cod_v INT;
	DECLARE spaz_disp FLOAT;
	-- cursore che scorre tutti i furgoni appartenenti ad un centro operativo
	DECLARE cursore1 CURSOR FOR SELECT v.codice_v FROM possiede AS p JOIN veicolo as v ON p.codice_v = v.codice_v
							    WHERE codice_co = cod_co and tipo_veicolo = "furgone";
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

		-- verifica se esiste un veicolo appartenente al centro operativo con abbastanza spazio disponibile per il pacco
		open cursore1;
		read_loop2: loop
			fetch cursore1 INTO cod_v;
			(SELECT spazio_disponibile FROM spazio_disponibile_veicolo WHERE codice_veicolo = cod_v) INTO spaz_disp;
			IF (spaz_disp > (SELECT lunghezza*larghezza*profondità FROM pacco WHERE codice_sp = cod_sp)) THEN
				-- se esiste un veicolo con spazio disponibile inserisce il seguente assegnamento
				INSERT INTO assegnamento VALUES (cod_v, cod_sp);
				LEAVE read_loop2;
			ELSEIF done THEN
				-- se non esiste il veicolo aggiorna la fase del pacco in "in attesa di recupero"
				INSERT INTO fase VALUES (CURRENT_TIMESTAMP, cod_sp, "in attesa di recupero");
				INSERT INTO riassegnazione_veicolo VALUES (cod_sp, cod_co, "ritiro");
				LEAVE read_loop2;
			END IF;
		END loop;
		close cursore1;

	-- COMMIT;
	
END //
DELIMITER ;



DELIMITER //

CREATE PROCEDURE riassegnazione_veicolo_pro (IN var_codice_sp INT, IN var_codice_co INT, IN var_tipo VARCHAR(45))
BEGIN
	DECLARE exit HANDLER FOR SQLEXCEPTION
	BEGIN	
		ROLLBACK;
		RESIGNAL;
	END;

		IF (var_tipo = "ritiro") THEN
			CALL start_ritiro_pacco (var_codice_sp, var_codice_co); 
		ELSE
			SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
			START TRANSACTION;
				DELETE FROM giacenza_pacchi_co WHERE codice_sp = var_codice_sp AND codice_co = var_codice_co;
				CALL inserimento_giacenza_pacchi_co (var_codice_co, var_codice_sp);
			COMMIT;
		END IF;
END //

DELIMITER ;




DELIMITER //
CREATE PROCEDURE inserimento_nuovo_pacco(IN var_codice_sp INT, IN var_peso SMALLINT, IN var_lunghezza SMALLINT, 
	IN var_larghezza SMALLINT, IN var_profondità SMALLINT)
BEGIN
	DECLARE dist FLOAT;
	DECLARE ind INT;
	DECLARE co1 INT;
	DECLARE co2 INT;
	DECLARE co3 INT;
	DECLARE co4 INT;
	DECLARE co5 INT;
	DECLARE co6 INT;


	INSERT INTO pacco (codice_sp, peso, lunghezza, larghezza, profondità)
	VALUES (var_codice_sp, var_peso, var_lunghezza, var_larghezza, var_profondità);

	SET ind = 1;
	-- calcolo centro prossimità più vicino all'indirizzo di recupero
	SELECT codice_co
	FROM spedizione JOIN coordinata_ritiro_pacco_cliente on cf_cliente = cf_cl,
		 centro_operativo
	WHERE codice_spedizione = var_codice_sp AND
		  tipo_co = "centro prossimità" AND
		  distanza(latitudine, longitudine, 
		  latitudine_cl, longitudine_cl) = (SELECT min(distanza(latitudine, longitudine, 
		  											latitudine_cl, longitudine_cl))
					  						FROM spedizione JOIN coordinata_ritiro_pacco_cliente on cf_cliente = cf_cl,
					  	   						  centro_operativo
		  									WHERE codice_spedizione = var_codice_sp
		  										  AND tipo_co = "centro prossimità") INTO co1;


	-- inserimento centro di prossimità addetto al ritiro del pacco
	INSERT INTO affidata_a VALUES (var_codice_sp, co1, ind);
	SET ind = ind + 1;
	
	-- calcolo distanza cliente-destinazione
	SELECT distanza(latitudine_des, longitudine_des, latitudine_cl, longitudine_cl)
	FROM spedizione JOIN coordinata_ritiro_pacco_cliente ON cf_cliente = cf_cl
	WHERE codice_spedizione = var_codice_sp INTO dist;

	-- se la distanza è minore di 40 sarà lo stesso centro di prossimità che ha ritirato
	-- il pacco ad occuparsi della consegna
	IF ( dist > 40) THEN
		-- cerco il centro di smistamento nazionale più vicino al centro di prossimità
		-- che ha ritirato il pacco
		SELECT c2.codice_co
		FROM centro_operativo AS c1, centro_operativo AS c2 
		WHERE c1.codice_co = co1 AND c2.codice_co != co1 AND c2.tipo_co = "centro smistamento nazionale" 
			AND distanza(c1.latitudine, c1.longitudine,
			c2.latitudine, c2.longitudine) = (SELECT min(distanza(c1.latitudine, c1.longitudine,
													c2.latitudine, c2.longitudine))
											  FROM centro_operativo AS c1, centro_operativo AS c2 
											  WHERE c1.codice_co = co1 AND c2.codice_co != co1
											 	 AND c2.tipo_co = "centro smistamento nazionale") INTO co2;

		INSERT INTO affidata_a VALUES (var_codice_sp, co2, ind);
		SET ind = ind + 1 ;


		-- verifico se la spedizione è del tipo internazionale
		IF ( (SELECT tipo_spedizione FROM spedizione WHERE codice_spedizione = var_codice_sp) = "internazionale") THEN 
			-- cerco il centro di smistamento internazionale più vicino al centro di smistamento 
			-- nazionale precedentemente scelto
			SELECT c2.codice_co
			FROM centro_operativo AS c1, centro_operativo AS c2 
			WHERE c1.codice_co = co2 AND c2.codice_co != co2 AND c2.tipo_co = "centro smistamento internazionale"
				AND distanza(c1.latitudine, c1.longitudine,
				c2.latitudine, c2.longitudine) = (SELECT min(distanza(c1.latitudine, c1.longitudine,
													c2.latitudine, c2.longitudine))
											  	FROM centro_operativo AS c1, centro_operativo AS c2 
											  	WHERE c1.codice_co = co2 AND c2.codice_co != co2
											  		AND c2.tipo_co = "centro smistamento internazionale") INTO co3;

			INSERT INTO affidata_a VALUES (var_codice_sp, co3, ind);
			SET ind = ind + 1;



			-- cerco il centro di smistamento internazionale più vicino al destinatario
			SELECT codice_co
			FROM spedizione, centro_operativo
			WHERE spedizione.codice_spedizione = var_codice_sp AND
				codice_co != co3 AND
				tipo_co = "centro smistamento internazionale" AND
				distanza(latitudine, longitudine, latitudine_des, longitudine_des) = (SELECT min(distanza(latitudine, longitudine, latitudine_des, longitudine_des))
																					  FROM spedizione, centro_operativo
																					  WHERE spedizione.codice_spedizione = var_codice_sp AND
																					  		codice_co != co3 AND
																					  		tipo_co = "centro smistamento internazionale") INTO co4;


			INSERT INTO affidata_a VALUES (var_codice_sp, co4, ind);
			SET ind = ind + 1;
																					
		END IF;

		-- cerco il centro di smistamento nazionale più vicino al destinatario
		SELECT codice_co
		FROM spedizione, centro_operativo
		WHERE spedizione.codice_spedizione = var_codice_sp AND
			codice_co != co2 AND
			tipo_co = "centro smistamento nazionale" AND
			distanza (latitudine, longitudine, latitudine_des, longitudine_des) = (SELECT min(distanza (latitudine, longitudine, latitudine_des, longitudine_des))
																				   FROM spedizione, centro_operativo
																				   WHERE spedizione.codice_spedizione = var_codice_sp AND
																				   		codice_co != co2 AND
																					  	tipo_co = "centro smistamento nazionale") INTO co5;

		INSERT INTO affidata_a VALUES (var_codice_sp, co5, ind);
		SET ind = ind + 1;


	 	-- cerco il centro di prossimità più vicino al destinatario
	 	SELECT codice_co
		FROM spedizione, centro_operativo
		WHERE spedizione.codice_spedizione = var_codice_sp AND
			codice_co != co1 AND
			tipo_co = "centro prossimità" AND
			distanza (latitudine, longitudine, latitudine_des, longitudine_des) = (SELECT min(distanza (latitudine, longitudine, latitudine_des, longitudine_des))
																				   FROM spedizione, centro_operativo
																				   WHERE spedizione.codice_spedizione = var_codice_sp AND
																				   		codice_co != co1 AND
																					  	tipo_co = "centro prossimità") INTO co6;

		INSERT INTO affidata_a VALUES (var_codice_sp, co6, ind);

	END IF;

	-- inserisce il pacco all'interno di giacenza_pacchi_co per "avvertire" il centro di prossimità
	-- che dovrà occuparsi del ritiro del pacco
	CALL start_ritiro_pacco(var_codice_sp, co1);

END//

DELIMITER ;




DELIMITER //
CREATE PROCEDURE inserimento_nuova_spedizione(OUT codice_sp INT,  
	IN var_cf_cliente CHAR(16), IN var_latitudine_des FLOAT, IN var_longitudine_des FLOAT)
BEGIN
	DECLARE retval INT;

		INSERT INTO spedizione(cf_cliente, latitudine_des, longitudine_des)
		VALUES (var_cf_cliente, var_latitudine_des, var_longitudine_des);
		SELECT max(codice_spedizione) FROM spedizione INTO codice_sp; 

	-- COMMIT;
END //
DELIMITER ;




DELIMITER //

CREATE PROCEDURE crea_nuovo_ordine (IN var_latitudine_des FLOAT, IN var_longitudine_des FLOAT, IN var_nome VARCHAR(45)
	, IN var_cognome VARCHAR(45), IN var_nazione VARCHAR(45), IN var_cf_cliente CHAR(16), IN var_peso SMALLINT, 
	IN var_lunghezza SMALLINT, IN var_larghezza SMALLINT, IN var_profondità SMALLINT, OUT costo FLOAT, OUT codice INT)
BEGIN
	DECLARE somma FLOAT;
	DECLARE volume_massimo FLOAT;

	DECLARE exit HANDLER FOR SQLEXCEPTION
	BEGIN	
		ROLLBACK;
		RESIGNAL;
	END;

	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
	START TRANSACTION;

		insert into destinatario (latitudine, longitudine, nome, cognome, nazione)
		values (var_latitudine_des, var_longitudine_des, var_nome, var_cognome, var_nazione) on duplicate key update nome=nome;

		CALL inserimento_nuova_spedizione(@codice_sp, var_cf_cliente, var_latitudine_des, var_longitudine_des);

		CALL inserimento_nuovo_pacco(@codice_sp,var_peso, var_lunghezza, var_larghezza, var_profondità);
		
		SET somma = var_larghezza * var_lunghezza * var_profondità;
		SELECT min(valore_volumetrico) FROM veicolo INTO volume_massimo;
		IF (somma > volume_massimo) THEN 
			SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = "non è possibile spedire il pacco, dimensione troppo grande";
		ELSE
			INSERT INTO fase VALUES (CURRENT_TIMESTAMP, @codice_sp, "accettata");
		END IF;

		SELECT stima_costo FROM costo_spedizione WHERE codice_spedizione = @codice_sp INTO costo;
		SET codice = @codice_sp;

	COMMIT;


END //

DELIMITER ;




DELIMITER //

CREATE PROCEDURE login (IN var_username VARCHAR(45), IN var_pass VARCHAR(45), OUT var_role INT)
BEGIN
	DECLARE var_user_role ENUM("amministratore", "cliente", "centro", "veicolo");

	SELECT ruolo 
	FROM utenti
	WHERE username = var_username AND password = md5(var_pass) INTO var_user_role;

	IF var_user_role = "amministratore" THEN
		SET var_role = 1;
	ELSEIF var_user_role = "cliente" THEN 
		SET var_role = 2;
	ELSEIF var_user_role = "centro" THEN 
		SET var_role = 3;
	ELSEIF var_user_role = "veicolo" THEN 
		SET var_role = 4;
	ELSE
		SET var_role = 5;
	END IF;
END //

DELIMITER ;



DELIMITER //
CREATE PROCEDURE crea_utente (IN username varchar(45), IN pass varchar(45), IN ruolo varchar(45))
BEGIN
	INSERT INTO utenti VALUES (username, md5(pass), ruolo);
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE registra_nuovo_cliente (IN cf CHAR(16), IN nome_cliente VARCHAR(45), IN cognome_cliente VARCHAR(45),
			IN data_di_nascita DATE, IN via_residenza VARCHAR(90), IN città_residenza VARCHAR(45),
			IN cap_residenza INT UNSIGNED, IN provincia_residenza VARCHAR(45), IN via_fatturazione VARCHAR(90),
			IN città_fatturazione VARCHAR(45), IN cap_fatturazione INT UNSIGNED, 
			IN provincia_fatturazione VARCHAR(45), IN numero BIGINT UNSIGNED, 
			IN nome_intestatario VARCHAR(45), IN cognome_intestario VARCHAR(45), IN data_di_scadenza DATE, 
			IN codice_cvv SMALLINT UNSIGNED,IN cliente_titolare CHAR(16), IN latitudine FLOAT, IN longitudine FLOAT, 
			IN username VARCHAR(45), IN password VARCHAR(45))
BEGIN
	
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		RESIGNAL;
	END;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	START TRANSACTION;

		CALL crea_utente(username, password, "cliente");

		INSERT INTO cliente VALUES (cf, nome_cliente, cognome_cliente, data_di_nascita, via_residenza, città_residenza, 
			cap_residenza, provincia_residenza, via_fatturazione, città_fatturazione, cap_fatturazione,
			provincia_fatturazione, username);

		INSERT INTO carta_di_credito VALUES (numero, nome_intestatario, cognome_intestario, data_di_scadenza, codice_cvv, cliente_titolare);

		INSERT INTO coordinate_cliente VALUES (cf, latitudine, longitudine);

	COMMIT;
END //
DELIMITER ;



DELIMITER //
CREATE PROCEDURE aggiungi_recapiti (IN cellulare INT UNSIGNED, IN telefono INT UNSIGNED, IN email VARCHAR(60), IN cf CHAR(16))
BEGIN
	INSERT INTO recapiti VALUES (cellulare, telefono, email, cf);
END//
DELIMITER ;



DELIMITER //
CREATE PROCEDURE visualizza_posizione_pacco(IN codice_sp INT UNSIGNED, IN cf CHAR(16), OUT lat FLOAT, OUT lon FLOAT)
BEGIN 
	SET TRANSACTION READ ONLY;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		SELECT latitudine, longitudine
		FROM posizione_pacco JOIN fase ON posizione_pacco.codice_spedizione = fase.codice_sp
		JOIN spedizione ON spedizione.codice_spedizione = fase.codice_sp
		WHERE nome = "in transito" AND codice_sp = posizione_pacco.codice_spedizione 
		AND cf_cliente = cf
		AND data_ora = (SELECT max(data_ora) 
						FROM fase
						WHERE codice_sp = fase.codice_sp) INTO lat, lon;
	COMMIT;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE check_tipo_co(IN cod_co INT UNSIGNED, OUT tipo VARCHAR(45))
BEGIN
	SET TRANSACTION READ ONLY;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
		SELECT tipo_co
		FROM centro_operativo
		WHERE cod_co = codice_co INTO tipo;
	COMMIT;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE stato_spedizione(IN cod_sp INT UNSIGNED, IN cf CHAR(16))
BEGIN
	SET TRANSACTION READ ONLY;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
		SELECT nome, data_ora
		FROM fase JOIN spedizione ON codice_sp = codice_spedizione
		WHERE cf = cf_cliente AND codice_sp = cod_sp;
	COMMIT;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE return_cf(IN username_cliente VARCHAR(45), OUT cf_cliente CHAR(16))
BEGIN	
	SET TRANSACTION READ ONLY;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
		SELECT cf 
		FROM cliente
		WHERE username_cliente = username INTO cf_cliente;
	COMMIT;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE conferma_addebita(IN codice_sp INT UNSIGNED, IN codice_co INT UNSIGNED, IN costo_effettivo FLOAT UNSIGNED)
BEGIN
	DECLARE num_carta BIGINT UNSIGNED;

	SET TRANSACTION READ ONLY;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	SELECT numero 
	FROM cliente JOIN spedizione ON cf_cliente = cf 
	JOIN carta_di_credito ON cf = cliente_titolare
	WHERE codice_spedizione = codice_sp INTO num_carta;

	INSERT INTO pagamento VALUES (codice_sp, codice_co, num_carta, costo_effettivo);
	COMMIT;
END //
DELIMITER ;



DELIMITER //
CREATE PROCEDURE report_giornaliero(OUT num_sp_accettate INT, OUT num_sp_consegnate INT, OUT entrate_tot FLOAT)
BEGIN
	SET TRANSACTION READ ONLY;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
		SELECT sp_accettate, sp_consegnate, entrate_totali
		FROM spedizioni_consegnate_24H, spedizioni_accettate_24H;
	COMMIT;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE modifica_categoria(IN nome_cat VARCHAR(45), IN prezzo FLOAT UNSIGNED, IN dim_minima FLOAT, IN dim_massima FLOAT)
BEGIN
	INSERT INTO categoria (nome, prezzo_base, dimensione_minima, dimensione_massima) 
	VALUES (nome_cat, prezzo, dim_minima, dim_massima) 
	ON DUPLICATE KEY UPDATE prezzo_base = VALUES(prezzo_base), 
	dimensione_minima = VALUES(dimensione_minima), dimensione_massima = VALUES(dimensione_massima);
END //
DELIMITER ;



DELIMITER //
CREATE PROCEDURE aggiorna_posizione(IN lat FLOAT, IN lon FLOAT, IN targa CHAR(7))
BEGIN
	UPDATE veicolo 
	SET latitudine = lat, longitudine = lon
	WHERE veicolo.targa = targa;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE aggiorna_coordinate_recupero_pacco(IN cf CHAR(16), IN lat FLOAT, IN lon FLOAT)
BEGIN
	UPDATE coordinate_cliente
	SET latitudine_cgr = lat, longitudine_cgr = lon
	WHERE cf = cf_cliente;
END //
DELIMITER ;




-- events


SET GLOBAL EVENT_SCHEDULER = ON;

CREATE EVENT report
ON SCHEDULE EVERY 1 day
ON COMPLETION NOT PRESERVE
DO 
	SELECT sp_accettate, sp_consegnate, entrate_totali
	FROM spedizioni_accettate_24H, spedizioni_consegnate_24H;




SET GLOBAL EVENT_SCHEDULER = ON;

DELIMITER //
CREATE EVENT riassegnazione
ON SCHEDULE EVERY 1 day
ON COMPLETION PRESERVE
DO 
	BEGIN
		DECLARE done INT DEFAULT FALSE;
		DECLARE cod_sp INT;
		DECLARE cod_co INT;
		DECLARE type VARCHAR(45);

		DECLARE cursore1 CURSOR FOR SELECT codice_sp FROM riassegnazione_veicolo;
		DECLARE cursore2 CURSOR FOR SELECT codice_co FROM riassegnazione_veicolo;
		DECLARE cursore3 CURSOR FOR SELECT tipo FROM riassegnazione_veicolo;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

		open cursore1;
		open cursore2;
		open cursore3;

		read_loop: loop
			fetch cursore1 INTO cod_sp;
			fetch cursore2 INTO cod_co;
			fetch cursore3 INTO type;

			IF done THEN 
				LEAVE read_loop;
			END IF;

			CALL riassegnazione_veicolo_pro(cod_sp, cod_co, type);
			DELETE FROM riassegnazione_veicolo WHERE codice_sp = cod_sp AND codice_co = cod_co;
		END loop;
		close cursore1;
		close cursore2;
		close cursore3;
	END //
DELIMITER ;





-- utenti
DROP USER IF EXISTS amministratore;
CREATE USER 'amministratore' IDENTIFIED BY 'amministratore';

DROP USER IF EXISTS cliente;
CREATE USER 'cliente' IDENTIFIED BY 'cliente';

DROP USER IF EXISTS centro;
CREATE USER 'centro' IDENTIFIED BY 'centro';

DROP USER IF EXISTS login;
CREATE USER 'login' IDENTIFIED BY 'login';

DROP USER IF EXISTS veicolo;
CREATE USER 'veicolo' IDENTIFIED BY 'veicolo';

-- privilegi

GRANT EXECUTE ON PROCEDURE report_giornaliero TO 'amministratore';
GRANT EXECUTE ON PROCEDURE modifica_categoria TO 'amministratore';

GRANT EXECUTE ON PROCEDURE login TO 'login';
GRANT EXECUTE ON PROCEDURE registra_nuovo_cliente TO 'login';

GRANT EXECUTE ON PROCEDURE crea_nuovo_ordine TO 'cliente';
GRANT EXECUTE ON PROCEDURE aggiungi_recapiti TO 'cliente';
GRANT EXECUTE ON PROCEDURE visualizza_posizione_pacco TO 'cliente';
GRANT EXECUTE ON PROCEDURE stato_spedizione TO 'cliente';
GRANT EXECUTE ON PROCEDURE return_cf TO 'cliente';
GRANT EXECUTE ON PROCEDURE aggiorna_coordinate_recupero_pacco TO 'cliente';

GRANT EXECUTE ON PROCEDURE inserimento_giacenza_pacchi_co TO 'centro';
GRANT EXECUTE ON PROCEDURE check_tipo_co TO 'centro';
GRANT EXECUTE ON PROCEDURE conferma_addebita TO 'centro';

GRANT EXECUTE ON PROCEDURE aggiorna_posizione TO 'veicolo';






-- instanziazione 

insert into categoria 
values ("piccola", 10, 0, 100),
("media", 40, 100, 500),
("grande", 80, 500, 2000);



insert into veicolo
values (1, "aa111aa", 2000, "furgone", 41, 41),
(2, "aa222aa", 2000, "furgone", 89, 23),
(3, "aa333aa", 2000, "furgone", 89, 23),
(4, "aa444aa", 2000, "furgone", 89, 23),
(5, "aa555aa", 2000, "furgone", 89, 23),
(6, "aa666aa", 2000, "furgone", 89, 23),
(7, "aa777aa", 10000, "autoarticolato", 89, 23),
(8, "aa888aa", 10000, "autoarticolato", 89, 23),
(9, "aa999aa", 10000, "autoarticolato", 89, 23),
(10, "aa000bb", 10000, "autoarticolato", 89, 23),
(11, "aa111bb", 2000, "furgone", 89, 23),
(12, "aa222bb", 2000, "furgone", 89, 23),
(13, "aa333bb", 2000, "furgone", 89, 23),
(14, "aa444bb", 2000, "furgone", 89, 23),
(15, "aa555bb", 10000, "autoarticolato", 89, 23),
(16, "aa666bb", 10000, "autoarticolato", 89, 23),
(17, "aa777bb", 2000, "furgone", 89, 23),
(18, "aa888bb", 2000, "furgone", 89, 23),
(19, "aa999bb", 10000, "autoarticolato", 89, 23),
(20, "aa000cc", 10000, "autoarticolato", 89, 23),
(21, "aa111cc", 10000, "autoarticolato", 89, 23),
(22, "aa222cc", 10000, "autoarticolato", 89, 23);



INSERT INTO centro_operativo
VALUES (1, "via di panico 7", "roma", 00186, "roma", 069812846, 41.899992, 12.467946, "russo", "centroroma@gmail.com", "centro prossimità"),
(2, "via paolo orsi 15", "roma", 00178, "roma", 067323182, 41.821876, 12.584744, "verdi", "centroroma2@gmail.com", "centro prossimità"),
(3, "via camilla ravera 5", "roma", 00135, "roma", 068473192, 41.958950, 12.395798, "rossi", "centroroma3@gmail.com", "centro prossimità"),
(4, "via edimburgo 83", "roma", 00144, "roma", 06783256, 41.819247, 12.453754, "bianchi", "centroroma4@gmail.com", "centro smistamento nazionale"),
(5, "via pal grande 10", "fiumicino", 00054, "roma", 06532324, 41.771333, 12.264104, "romano", "centrofiumicino@gmail.com", "centro smistamento internazionale"),
(6, "via dei serragli 32", "firenze", 50125, "firenze", 05432654, 43.767032, 11.245384, "ricci", "centrofirenze@gmail.com", "centro prossimità"),
(7, "via amati 7", "pistoia", 51100, "pistoia", 05636734, 43.931099, 10.918457, "gatti", "centropistoia@gmail.com", "centro prossimità"),
(8, "via del pino 15", "firenze", 50137, "firenze", 05358796, 43.779575, 11.295022, "testa", "centrofirenze2@gmail.com", "centro smistamento nazionale"),
(9, "rue de rungis 14", "parigi", 75013, "parigi", 57389354, 48.821856, 2.344542, "fontana", "centroparigi@gmail.com", "centro prossimità"),
(10, "passage panel 8", "parigi", 75018, "parigi", 324235112, 48.896086, 2.342369, "ferrari", "centroparigi2@gmail.com", "centro smistamento nazionale"),
(11, "rue delagarde 41", "montfermeil", 93370, "parigi", 32434234, 48.902070, 2.568547, "costa", "centromontfermeil@gmail.com", "centro smistamento internazionale");



insert into possiede
values (1,1),
(1,2),
(2,3),
(2,4),
(3,5),
(3,6),
(4,7),
(4,8),
(5,9),
(5,10),
(6,11),
(6,12),
(7,13),
(7,14),
(8,15),
(8,16),
(9,17),
(9,18),
(10,19),
(10,20),
(11,21),
(11,22);


CALL crea_utente ("1", "uno", "centro");
CALL crea_utente ("2", "due", "centro");
CALL crea_utente ("3", "tre", "centro");
CALL crea_utente ("4", "quattro", "centro");
CALL crea_utente ("5", "cinque", "centro");
CALL crea_utente ("6", "sei", "centro");
CALL crea_utente ("7", "sette", "centro");
CALL crea_utente ("8", "otto", "centro");
CALL crea_utente ("9", "nove", "centro");
CALL crea_utente ("10", "dieci", "centro");
CALL crea_utente ("11", "undici", "centro");

CALL crea_utente ("admin", "ciao", "amministratore");

CALL crea_utente ("aa111aa", "ciao", "veicolo");
CALL crea_utente ("aa222aa", "ciao", "veicolo");
CALL crea_utente ("aa333aa", "ciao", "veicolo");
CALL crea_utente ("aa444aa", "ciao", "veicolo");
CALL crea_utente ("aa555aa", "ciao", "veicolo");
CALL crea_utente ("aa666aa", "ciao", "veicolo");
CALL crea_utente ("aa777aa", "ciao", "veicolo");
CALL crea_utente ("aa888aa", "ciao", "veicolo");
CALL crea_utente ("aa999aa", "ciao", "veicolo");
CALL crea_utente ("aa000bb", "ciao", "veicolo");
CALL crea_utente ("aa111bb", "ciao", "veicolo");
CALL crea_utente ("aa222bb", "ciao", "veicolo");
CALL crea_utente ("aa333bb", "ciao", "veicolo");
CALL crea_utente ("aa444bb", "ciao", "veicolo");
CALL crea_utente ("aa555bb", "ciao", "veicolo");
CALL crea_utente ("aa666bb", "ciao", "veicolo");
CALL crea_utente ("aa777bb", "ciao", "veicolo");
CALL crea_utente ("aa888bb", "ciao", "veicolo");
CALL crea_utente ("aa999bb", "ciao", "veicolo");
CALL crea_utente ("aa000cc", "ciao", "veicolo");
CALL crea_utente ("aa111cc", "ciao", "veicolo");
CALL crea_utente ("aa222cc", "ciao", "veicolo");



