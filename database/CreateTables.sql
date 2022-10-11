--TODO
--consider changing type of string-type data from text for performance?
--note: payer will be the insurance staff who approved a claim / the patient who is paying with credit card
-- we may want to find better solution for fkey on payer, for now we just fkey to user
--enums
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TYPE IF EXISTS account_type;
CREATE TYPE account_type AS ENUM('patient', 'doctor', 'hospital_staff', 'lab_staff', 'insurance_staff', 'admin');

DROP TYPE IF EXISTS status_type;
CREATE TYPE status_type AS ENUM('requested', 'approved', 'denied', 'completed', 'init_transaction', 'approved_transaction', 'insurance_transaction', 'completed_transaction', 'finished_transaction');

--user table
DROP TABLE IF EXISTS public.user;
CREATE TABLE IF NOT EXISTS public.user
(   
	"userID" SERIAL NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
	password text NOT NULL,
	"accountType" account_type NOT NULL,
	"startDate" date NOT NULL,
	"expiryDate" date,
    CONSTRAINT user_pkey PRIMARY KEY ("userID"),
    CONSTRAINT "Email" UNIQUE (email)
);

--Session table
DROP TABLE IF EXISTS public.session;
CREATE TABLE IF NOT EXISTS public.session
(
	"userID" integer NOT NULL,
	"startTime" timestamp NOT NULL,
	"sessionID" integer NOT NULL,
	CONSTRAINT session_pkey PRIMARY KEY ("userID"),
	CONSTRAINT "userID" FOREIGN KEY ("userID")
		REFERENCES public.user ("userID") MATCH SIMPLE
		ON UPDATE CASCADE
        ON DELETE CASCADE
);

--Password reset table
DROP TABLE IF EXISTS public."passwordReset";
CREATE TABLE IF NOT EXISTS public."passwordReset"
(
	"userID" integer NOT NULL,
	"email" text NOT NULL,
	"time" timestamp NOT NULL,
	CONSTRAINT password_reset_pkey PRIMARY KEY ("userID"),
	CONSTRAINT "userID" FOREIGN KEY ("userID")
		REFERENCES public.user ("userID") MATCH SIMPLE
		ON UPDATE CASCADE
        ON DELETE CASCADE
);

--One time passcode table
DROP TABLE IF EXISTS public."oneTimePasscode";
CREATE TABLE IF NOT EXISTS public."oneTimePasscode"
(
	"userID" integer NOT NULL,
	"passcode" text NOT NULL,
	"time" timestamp NOT NULL,
	CONSTRAINT otp_pkey PRIMARY KEY ("userID"),
	CONSTRAINT "userID" FOREIGN KEY ("userID")
		REFERENCES public.user ("userID") MATCH SIMPLE
		ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- doctor must be a table instead of view so I don't have to write triggers instead of foreign keys to reference it
-- still need to write triggers to auto-update it from user table tho
--due to cascade, no trigger needed for deletion, but updates that change accountType - this should not really be a functionality available to outfacing interface - need to be accounted for
DROP TABLE IF EXISTS public.doctor;
CREATE TABLE IF NOT EXISTS public.doctor
(
	"doctorID" integer NOT NULL,
	CONSTRAINT doctor_pkey PRIMARY KEY ("doctorID"),
	CONSTRAINT "userID" FOREIGN KEY ("doctorID")
		REFERENCES public.user ("userID") MATCH SIMPLE
		ON UPDATE CASCADE
        ON DELETE CASCADE
);
--this set of function and trigger checks all rows inserted into user table and updates doctor table accordingly
CREATE OR REPLACE FUNCTION new_doctor_insert() RETURNS TRIGGER AS
$BODY$
BEGIN
    INSERT INTO
        doctor("doctorID")
        VALUES(new."userID");
		
           RETURN new;
END;
$BODY$
language plpgsql;

DROP TRIGGER IF EXISTS new_doctor; 
CREATE TRIGGER new_doctor
	AFTER INSERT ON user
	FOR EACH ROW
	WHEN (NEW."accountType" = 'doctor')
	EXECUTE PROCEDURE new_doctor_insert();

--this set of function and trigger checks all rows updated in user table to become doctors and updates doctor table accordingly
CREATE OR REPLACE FUNCTION promoted_doctor_insert() RETURNS TRIGGER AS
$BODY$
BEGIN
    INSERT INTO
        doctor("doctorID")
        VALUES(new."userID");
		
           RETURN new;
END;
$BODY$
language plpgsql;

DROP TRIGGER IF EXISTS promoted_doctor;
CREATE TRIGGER promoted_doctor
	AFTER UPDATE ON user
	FOR EACH ROW
	WHEN (NEW."accountType" = 'doctor' AND OLD."accountType" != 'doctor')
	EXECUTE PROCEDURE promoted_doctor_insert();

--this set of function and trigger checks all rows updated in user table to cease being doctors and updates doctor table accordingly
CREATE OR REPLACE FUNCTION demoted_doctor_delete() RETURNS TRIGGER AS
$BODY$
BEGIN
    DELETE FROM doctor
    WHERE "doctorID" = new."userID";

           RETURN new;
END;
$BODY$
language plpgsql;

DROP TRIGGER IF EXISTS demoted_doctor;
CREATE TRIGGER demoted_doctor
	AFTER UPDATE ON user
	FOR EACH ROW
	WHEN (OLD."accountType" = 'doctor' AND NEW."accountType" != 'doctor')
	EXECUTE PROCEDURE demoted_doctor_delete();
	
-- insuranceStaff, same as doctor 
DROP TABLE IF EXISTS public."insuranceStaff";
CREATE TABLE IF NOT EXISTS public."insuranceStaff"
(
	"istaffID" integer NOT NULL,
	CONSTRAINT istaff_pkey PRIMARY KEY ("istaffID"),
	CONSTRAINT "userID" FOREIGN KEY ("istaffID")
		REFERENCES public.user ("userID") MATCH SIMPLE
		ON UPDATE CASCADE
        ON DELETE CASCADE
);
--this set of function and trigger checks all rows inserted into user table and updates insuranceStaff table accordingly
CREATE OR REPLACE FUNCTION new_istaff_insert() RETURNS TRIGGER AS
$BODY$
BEGIN
    INSERT INTO
        "insuranceStaff"("istaffID")
        VALUES(new."userID");
		
           RETURN new;
END;
$BODY$
language plpgsql;

DROP TRIGGER IF EXISTS new_istaff;
CREATE TRIGGER new_istaff
	AFTER INSERT ON user
	FOR EACH ROW
	WHEN (NEW."accountType" = 'insurance_staff')
	EXECUTE PROCEDURE new_istaff_insert();

--this set of function and trigger checks all rows updated in user table to become doctors and updates doctor table accordingly
CREATE OR REPLACE FUNCTION promoted_istaff_insert() RETURNS TRIGGER AS
$BODY$
BEGIN
    INSERT INTO
        "insuranceStaff"("istaffID")
        VALUES(new."userID");
		
           RETURN new;
END;
$BODY$
language plpgsql;

DROP TRIGGER IF EXISTS promoted_istaff;
CREATE TRIGGER promoted_istaff
	AFTER UPDATE ON user
	FOR EACH ROW
	WHEN (NEW."accountType" = 'insurance_staff' AND OLD."accountType" != 'insurance_staff')
	EXECUTE PROCEDURE promoted_istaff_insert();

--this set of function and trigger checks all rows updated in user table to cease being doctors and updates doctor table accordingly
CREATE OR REPLACE FUNCTION demoted_istaff_delete() RETURNS TRIGGER AS
$BODY$
BEGIN
    DELETE FROM "insuranceStaff"
    WHERE "istaffID" = new."userID";

           RETURN new;
END;
$BODY$
language plpgsql;

DROP TRIGGER IF EXISTS demoted_istaff;
CREATE TRIGGER demoted_istaff
	AFTER UPDATE ON user
	FOR EACH ROW
	WHEN (OLD."accountType" = 'insurance_staff' AND NEW."accountType" != 'insurance_staff')
	EXECUTE PROCEDURE demoted_istaff_delete();

-- hospitalStaff, same as doctor 
DROP TABLE IF EXISTS public."hospitalStaff";
CREATE TABLE IF NOT EXISTS public."hospitalStaff"
(
	"hstaffID" integer NOT NULL,
	CONSTRAINT hstaff_pkey PRIMARY KEY ("hstaffID"),
	CONSTRAINT "userID" FOREIGN KEY ("hstaffID")
		REFERENCES public.user ("userID") MATCH SIMPLE
		ON UPDATE CASCADE
        ON DELETE CASCADE
);
--this set of function and trigger checks all rows inserted into user table and updates insuranceStaff table accordingly
CREATE OR REPLACE FUNCTION new_hstaff_insert() RETURNS TRIGGER AS
$BODY$
BEGIN
    INSERT INTO
        "hospitalStaff"("hstaffID")
        VALUES(new."userID");
		
           RETURN new;
END;
$BODY$
language plpgsql;

DROP TRIGGER IF EXISTS new_hstaff;
CREATE TRIGGER new_hstaff
	AFTER INSERT ON user
	FOR EACH ROW
	WHEN (NEW."accountType" = 'hospital_staff')
	EXECUTE PROCEDURE new_hstaff_insert();

--this set of function and trigger checks all rows updated in user table to become doctors and updates doctor table accordingly
CREATE OR REPLACE FUNCTION promoted_hstaff_insert() RETURNS TRIGGER AS
$BODY$
BEGIN
    INSERT INTO
        "hospitalStaff"("hstaffID")
        VALUES(new."userID");
		
           RETURN new;
END;
$BODY$
language plpgsql;

DROP TRIGGER IF EXISTS promoted_hstaff;
CREATE TRIGGER promoted_hstaff
	AFTER UPDATE ON user
	FOR EACH ROW
	WHEN (NEW."accountType" = 'hospital_staff' AND OLD."accountType" != 'hospital_staff')
	EXECUTE PROCEDURE promoted_hstaff_insert();

--this set of function and trigger checks all rows updated in user table to cease being doctors and updates doctor table accordingly
CREATE OR REPLACE FUNCTION demoted_hstaff_delete() RETURNS TRIGGER AS
$BODY$
BEGIN
    DELETE FROM "hospitalStaff"
    WHERE "hstaffID" = new."userID";

           RETURN new;
END;
$BODY$
language plpgsql;

DROP TRIGGER IF EXISTS demoted_hstaff;
CREATE TRIGGER demoted_hstaff
	AFTER UPDATE ON user
	FOR EACH ROW
	WHEN (OLD."accountType" = 'hospital_staff' AND NEW."accountType" != 'hospital_staff')
	EXECUTE PROCEDURE demoted_hstaff_delete();

-- labStaff, same as doctor 
DROP TABLE IF EXISTS public."labStaff";
CREATE TABLE IF NOT EXISTS public."labStaff"
(
	"lstaffID" integer NOT NULL,
	CONSTRAINT lstaff_pkey PRIMARY KEY ("lstaffID"),
	CONSTRAINT "userID" FOREIGN KEY ("lstaffID")
		REFERENCES public.user ("userID") MATCH SIMPLE
		ON UPDATE CASCADE
        ON DELETE CASCADE
);
--this set of function and trigger checks all rows inserted into user table and updates insuranceStaff table accordingly
CREATE OR REPLACE FUNCTION new_lstaff_insert() RETURNS TRIGGER AS
$BODY$
BEGIN
    INSERT INTO
        "labStaff"("lstaffID")
        VALUES(new."userID");
		
           RETURN new;
END;
$BODY$
language plpgsql;

DROP TRIGGER IF EXISTS new_lstaff;
CREATE TRIGGER new_lstaff
	AFTER INSERT ON user
	FOR EACH ROW
	WHEN (NEW."accountType" = 'lab_staff')
	EXECUTE PROCEDURE new_lstaff_insert();

--this set of function and trigger checks all rows updated in user table to become doctors and updates doctor table accordingly
CREATE OR REPLACE FUNCTION promoted_lstaff_insert() RETURNS TRIGGER AS
$BODY$
BEGIN
    INSERT INTO
        "labStaff"("lstaffID")
        VALUES(new."userID");
		
           RETURN new;
END;
$BODY$
language plpgsql;

DROP TRIGGER IF EXISTS promoted_lstaff;
CREATE TRIGGER promoted_lstaff
	AFTER UPDATE ON user
	FOR EACH ROW
	WHEN (NEW."accountType" = 'lab_staff' AND OLD."accountType" != 'lab_staff')
	EXECUTE PROCEDURE promoted_lstaff_insert();

--this set of function and trigger checks all rows updated in user table to cease being doctors and updates doctor table accordingly
CREATE OR REPLACE FUNCTION demoted_lstaff_delete() RETURNS TRIGGER AS
$BODY$
BEGIN
    DELETE FROM "labStaff"
    WHERE "lstaffID" = new."userID";

           RETURN new;
END;
$BODY$
language plpgsql;

DROP TRIGGER IF EXISTS demoted_lstaff;
CREATE TRIGGER demoted_lstaff
	AFTER UPDATE ON user
	FOR EACH ROW
	WHEN (OLD."accountType" = 'lab_staff' AND NEW."accountType" != 'lab_staff')
	EXECUTE PROCEDURE demoted_lstaff_delete();

--patient table
DROP TABLE IF EXISTS public.patient;
CREATE TABLE IF NOT EXISTS public.patient
(
	"patientID" integer NOT NULL,
    age integer NOT NULL,
    gender text COLLATE pg_catalog."default" NOT NULL,
    address text COLLATE pg_catalog."default" NOT NULL,
    "phoneNumber" text NOT NULL, -- might change data type on this later
    "creditCard" text COLLATE pg_catalog."default" NOT NULL,
	CONSTRAINT patient_pkey PRIMARY KEY ("patientID"),
    CONSTRAINT "userID" FOREIGN KEY ("userID")
        REFERENCES public."user" ("patientID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

--availability table
DROP TABLE IF EXISTS public.availability;
CREATE TABLE IF NOT EXISTS public.availability
(
    "doctorID" integer NOT NULL,
    date date NOT NULL,
    "time" time with time zone NOT NULL,
    CONSTRAINT availability_pkey PRIMARY KEY ("doctorID", date, "time"),
    CONSTRAINT doctor FOREIGN KEY ("doctorID")
        REFERENCES public.doctor ("doctorID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

--diagnosis table
DROP TABLE IF EXISTS public.diagnosis;
CREATE TABLE IF NOT EXISTS public.diagnosis
(
	"patientID" integer NOT NULL,
	"doctorID" integer NOT NULL,
	"date" date NOT NULL,
	diagnosis text NOT NULL,
	CONSTRAINT diagnosis_pkey PRIMARY KEY ("patientID", "doctorID", "date"),
	CONSTRAINT "patient" FOREIGN KEY ("patientID") 
		REFERENCES public.patient ("patientID") MATCH SIMPLE
		ON UPDATE CASCADE
        ON DELETE CASCADE,
	CONSTRAINT "doctor" FOREIGN KEY ("doctorID")
		REFERENCES public.doctor ("doctorID") MATCH SIMPLE
		ON UPDATE CASCADE
        ON DELETE CASCADE
);

--record table
DROP TABLE IF EXISTS public.record;
CREATE TABLE IF NOT EXISTS public."record"
(
	"patientID" integer NOT NULL,
	"recordID" integer NOT NULL,
	"record" text NOT NULL,
	"inputter" integer NOT NULL,
	"date" date NOT NULL,
	CONSTRAINT record_pkey PRIMARY KEY ("patientID", "recordID"),
	CONSTRAINT "patient" FOREIGN KEY ("patientID")
		REFERENCES public.patient ("patientID") MATCH SIMPLE
		ON UPDATE CASCADE
        ON DELETE CASCADE,
	CONSTRAINT inputter_user FOREIGN KEY ("inputter")
		REFERENCES public."hospitalStaff" ("hstaffID") MATCH SIMPLE
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

--labTest table
DROP TABLE IF EXISTS public."labTest";
CREATE TABLE IF NOT EXISTS public."labTest"
(
    "patientID" integer NOT NULL,
    "testName" text COLLATE pg_catalog."default" NOT NULL,
    record text COLLATE pg_catalog."default",
    inputter integer,
    "dateRecommended" date NOT NULL,
    recommender integer NOT NULL,
    "dateFilled" date,
    status status_type NOT NULL DEFAULT 'requested'::status_type,
    CONSTRAINT labtest_pkey PRIMARY KEY ("patientID", "testName", "dateRecommended"),
    CONSTRAINT inputter_user FOREIGN KEY (inputter)
        REFERENCES public."labStaff" ("lstaffID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT recommender_user FOREIGN KEY (recommender)
        REFERENCES public.doctor ("doctorID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

--bill table
DROP TABLE IF EXISTS public.bill;
CREATE TABLE IF NOT EXISTS public.bill
(
    "patientID" integer NOT NULL,
    "transactionID" integer NOT NULL,
    service text COLLATE pg_catalog."default" NOT NULL,
    amount numeric NOT NULL,
    date date NOT NULL,
	"status" status_type NOT NULL DEFAULT 'requested'::status_type,
    CONSTRAINT bill_pkey PRIMARY KEY ("transactionID"),
    CONSTRAINT patient FOREIGN KEY ("patientID")
        REFERENCES public.patient ("patientID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT transaction_fkey FOREIGN KEY ("transactionID")
        REFERENCES public.transaction ("transactionID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

--transaction table
DROP TABLE IF EXISTS public.transaction;
CREATE TABLE IF NOT EXISTS public.transaction
(
	"transactionID" SERIAL NOT NULL,
	"transactionAmount" numeric NOT NULL,
	"payer" integer NOT NULL,
	"status" status_type NOT NULL DEFAULT 'requested'::status_type,
	"date" date NOT NULL,
	CONSTRAINT transaction_pkey PRIMARY KEY ("billID", "transactionID"),
	CONSTRAINT "bill" FOREIGN KEY ("patientID", "billID")
		REFERENCES public.bill ("patientID", "billID") MATCH SIMPLE
		ON UPDATE CASCADE
        ON DELETE CASCADE,
	CONSTRAINT payer_user FOREIGN KEY ("payer")
		REFERENCES public.patient ("patientID") MATCH SIMPLE
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

-- insuranceClaim table
DROP TABLE IF EXISTS public."insuranceClaim";
CREATE TABLE IF NOT EXISTS public."insuranceClaim"
(
    "transactionID" integer NOT NULL,
    "dateOfRequest" date NOT NULL,
    "dateOfApprove" date NOT NULL,
    "claimedAmount" numeric NOT NULL,
    "approvedAmount" numeric NOT NULL,
    approver integer,
    date date NOT NULL,
    status status_type NOT NULL DEFAULT 'requested'::status_type,
    CONSTRAINT insurance_pkey PRIMARY KEY ("transactionID"),
    CONSTRAINT approver_user FOREIGN KEY (approver)
        REFERENCES public."insuranceStaff" ("istaffID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT transaction_fkey FOREIGN KEY ("transactionID")
        REFERENCES public.transaction ("transactionID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
--insurancePolicy table
DROP TABLE IF EXISTS public."insurancePolicy";
CREATE TABLE IF NOT EXISTS public."insurancePolicy"
(
    "policyID" SERIAL NOT NULL,
    "patientID" integer NOT NULL,
    amount numeric NOT NULL,
    "policyDetails" text COLLATE pg_catalog."default",
    CONSTRAINT policy_pkey PRIMARY KEY ("policyID"),
    CONSTRAINT patient FOREIGN KEY ("patientID")
        REFERENCES public.patient ("patientID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
-- appointment table
DROP TABLE IF EXISTS public.appointment;
CREATE TABLE IF NOT EXISTS public.appointment
(
    "patientID" integer NOT NULL,
    "doctorID" integer NOT NULL,
    "time" time with time zone NOT NULL,
    date date NOT NULL,
    approver integer,
    amount numeric,
    status status_type NOT NULL DEFAULT 'requested'::status_type,
    CONSTRAINT appointment_pkey PRIMARY KEY ("patientID", "doctorID", "time", date),
    CONSTRAINT approver_user FOREIGN KEY (approver)
        REFERENCES public."hospitalStaff" ("hstaffID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT available FOREIGN KEY ("time", date, "doctorID")
        REFERENCES public.availability ("time", date, "doctorID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT doctor FOREIGN KEY ("doctorID")
        REFERENCES public.doctor ("doctorID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT patient FOREIGN KEY ("patientID")
        REFERENCES public.patient ("patientID") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

--prescription table
DROP TABLE IF EXISTS public.prescription;
CREATE TABLE IF NOT EXISTS public.prescription
(
	"patientID" integer NOT NULL,
	"doctorID" integer NOT NULL,
	"date" date NOT NULL,
	"prescriptionID" SERIAL NOT NULL,
	"prescription" text NOT NULL, 
	CONSTRAINT prescription_pkey PRIMARY KEY ("prescriptionID"),
	CONSTRAINT "patient" FOREIGN KEY ("patientID")
		REFERENCES public.patient ("patientID") MATCH SIMPLE
		ON UPDATE CASCADE
        ON DELETE CASCADE,
	CONSTRAINT 	"doctor" FOREIGN KEY ("doctorID")
		REFERENCES public.doctor ("doctorID") MATCH SIMPLE
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

DROP TABLE IF EXISTS public.roles;
CREATE TABLE IF NOT EXISTS public.roles
(
    id integer NOT NULL,
    name account_type NOT NULL,
    CONSTRAINT pkey PRIMARY KEY (id),
    CONSTRAINT type UNIQUE (name)
);
INSERT INTO
	public.roles(id, name)
	VALUES(1, 'patient');
INSERT INTO
	public.roles(id, name)
	VALUES(2, 'doctor');
INSERT INTO
	public.roles(id, name)
	VALUES(3, 'hospital_staff');
INSERT INTO
	public.roles(id, name)
	VALUES(4, 'lab_staff');
INSERT INTO
	public.roles(id, name)
	VALUES(5, 'insurance_staff');
INSERT INTO
	public.roles(id, name)
	VALUES(6, 'admin');