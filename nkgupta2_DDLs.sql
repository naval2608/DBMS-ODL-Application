DROP TABLE HEALTH_FRIEND_ALERTS;
DROP TABLE MY_ALERTS;
DROP TABLE OBSERVATIONS_LOG;
DROP TABLE DISEASE_OBSERVATION_TYPE;
DROP TABLE OBSERVATION_TYPE_CATEGORY;
DROP TABLE OBSERVATION_TYPE;
DROP TABLE OBSERVATION_CATEGORY;
DROP TABLE ASSIGN_DISEASE;
DROP TABLE DISEASE_CLASS;
DROP TABLE HEALTH_FRIEND;
DROP TABLE PATIENT_ADDRESS;
DROP TABLE PATIENT;
DROP TABLE PHYSICIAN;
DROP TABLE USER_LOGIN;

DROP SEQUENCE ADDRESS_ID_SEQ;
DROP SEQUENCE DISEASE_CLASS_ID_SEQ;
DROP SEQUENCE OBSERVATION_CATEGORY_SEQ;
DROP SEQUENCE OBSERVATION_TYPE_SEQ;
DROP SEQUENCE OBSERVATIONS_LOG_SEQ;
DROP SEQUENCE MY_ALERTS_SEQ;
DROP SEQUENCE HEALTH_FRIEND_ALERTS_SEQ;

DROP PROCEDURE UPDATE_ALERTS;

--IS_PATIENT: IF PATIENT THEN 1 ELSE 0 FOR HEALTH SUPPORTERS.
CREATE TABLE USER_LOGIN(
USER_ID VARCHAR2(20) ,
PASSWORD VARCHAR2(20) ,
IS_PATIENT CHAR(1), 
PRIMARY KEY (USER_ID)
);

CREATE TABLE PHYSICIAN(
PHYSICIAN_ID VARCHAR2(20) ,
PHYSICIAN_NAME VARCHAR2(100) ,
CLINIC VARCHAR2(30),
PRIMARY KEY (PHYSICIAN_ID),
FOREIGN KEY (PHYSICIAN_ID) REFERENCES USER_LOGIN (USER_ID) ON DELETE CASCADE
);

CREATE OR REPLACE TRIGGER CHECK_UID_PHYSICIAN 
BEFORE INSERT ON PHYSICIAN
FOR EACH ROW
DECLARE 
IS_PATIENT_BIT CHAR(1);
BEGIN
SELECT IS_PATIENT INTO IS_PATIENT_BIT FROM USER_LOGIN U WHERE U.USER_ID= :new.PHYSICIAN_ID ; 
IF IS_PATIENT_BIT = '1' THEN
RAISE_APPLICATION_ERROR (-20000, 'USER_ID DOES NOT BELONG TO PHYSICIAN!');
END IF;
END;
/

CREATE TABLE PATIENT(
PATIENT_ID VARCHAR2(20) ,
PATIENT_NAME VARCHAR2(30) ,
AGE INTEGER,
SEX VARCHAR2(10),
PUBLIC_STATUS CHAR(1),
PRIMARY KEY (PATIENT_ID) ,
FOREIGN KEY (PATIENT_ID) REFERENCES USER_LOGIN (USER_ID) ON DELETE CASCADE
);

CREATE OR REPLACE TRIGGER CHECK_UID_PATIENT
BEFORE INSERT ON PATIENT
FOR EACH ROW
DECLARE 
IS_PATIENT_BIT CHAR(1);
BEGIN
SELECT IS_PATIENT INTO IS_PATIENT_BIT FROM USER_LOGIN U WHERE U.USER_ID= :new.PATIENT_ID ; 
IF IS_PATIENT_BIT <> '1' THEN
RAISE_APPLICATION_ERROR (-20000, 'USER_ID DOES NOT BELONG TO PHYSICIAN!');
END IF;
END;
/

CREATE TABLE PATIENT_ADDRESS(
ADDRESS_ID INTEGER,
PATIENT_ID VARCHAR2(20) NOT NULL,
STREET_ADDRESS VARCHAR2(100) ,
CITY VARCHAR2(30) ,
STATE_NAME CHAR(2) ,
ZIP INTEGER ,
PRIMARY KEY (ADDRESS_ID) ,
FOREIGN KEY (PATIENT_ID) REFERENCES PATIENT (PATIENT_ID) ON DELETE CASCADE
);



CREATE SEQUENCE ADDRESS_ID_SEQ;

CREATE OR REPLACE TRIGGER ADDRESS_ID_TRIG
BEFORE INSERT ON PATIENT_ADDRESS
FOR EACH ROW
BEGIN
SELECT ADDRESS_ID_SEQ.nextval INTO :new.ADDRESS_ID FROM dual;
END;
/

CREATE TABLE HEALTH_FRIEND(
PATIENT_ID VARCHAR2(20) ,
HEALTH_FRIEND_ID VARCHAR2(20) ,
DATE_OF_INITIATION DATE NOT NULL,
PRIMARY KEY (PATIENT_ID,HEALTH_FRIEND_ID) ,
FOREIGN KEY (PATIENT_ID) REFERENCES PATIENT (PATIENT_ID) ON DELETE CASCADE,
FOREIGN KEY (HEALTH_FRIEND_ID) REFERENCES PATIENT (PATIENT_ID) ON DELETE CASCADE,
CONSTRAINT VALID_HEALTH_FRIEND CHECK (PATIENT_ID <> HEALTH_FRIEND_ID)
);

CREATE TABLE DISEASE_CLASS(
CLASS_ID INTEGER ,
CLASS_NAME VARCHAR2(20),
PRIMARY KEY (CLASS_ID)
);

CREATE SEQUENCE DISEASE_CLASS_ID_SEQ;

CREATE OR REPLACE TRIGGER DISEASE_CLASS_ID
BEFORE INSERT ON DISEASE_CLASS
FOR EACH ROW
BEGIN
SELECT DISEASE_CLASS_ID_SEQ.nextval INTO :new.CLASS_ID FROM dual;
END;
/

CREATE TABLE ASSIGN_DISEASE(
PATIENT_ID VARCHAR2(20) ,
CLASS_ID INTEGER ,
PHYSICIAN_ID VARCHAR2(20) ,
PRIMARY KEY (PATIENT_ID,CLASS_ID),
FOREIGN KEY (PATIENT_ID) REFERENCES PATIENT (PATIENT_ID) ON DELETE CASCADE,
FOREIGN KEY (CLASS_ID) REFERENCES DISEASE_CLASS (CLASS_ID) ON DELETE CASCADE,
FOREIGN KEY (PHYSICIAN_ID) REFERENCES PHYSICIAN (PHYSICIAN_ID) ON DELETE SET NULL
);


CREATE TABLE OBSERVATION_CATEGORY(
CATEGORY_ID INTEGER ,
CATEGORY_NAME VARCHAR2(30) UNIQUE NOT NULL,
PRIMARY KEY (CATEGORY_ID)
);

CREATE SEQUENCE OBSERVATION_CATEGORY_SEQ;

CREATE OR REPLACE TRIGGER CATEGORY_ID_TRIG
BEFORE INSERT ON OBSERVATION_CATEGORY
FOR EACH ROW
BEGIN
SELECT OBSERVATION_CATEGORY_SEQ.nextval INTO :new.CATEGORY_ID FROM dual;
END;
/

CREATE TABLE OBSERVATION_TYPE(
TYPE_ID INTEGER ,
TYPE_NAME VARCHAR2(30) UNIQUE NOT NULL,
THRESHOLD_VAL VARCHAR2(10),
ADDITIONAL_INFO_1 VARCHAR2(100),
ADDITIONAL_INFO_2 VARCHAR2(100),
PRIMARY KEY (TYPE_ID)
);

CREATE SEQUENCE OBSERVATION_TYPE_SEQ;

CREATE OR REPLACE TRIGGER TYPE_ID_TRIG
BEFORE INSERT ON OBSERVATION_TYPE
FOR EACH ROW
BEGIN
SELECT OBSERVATION_TYPE_SEQ.nextval INTO :new.TYPE_ID FROM dual;
END;
/

CREATE TABLE OBSERVATION_TYPE_CATEGORY(
CATEGORY_ID INTEGER NOT NULL,
TYPE_ID INTEGER,
PRIMARY KEY (TYPE_ID),
FOREIGN KEY (CATEGORY_ID) REFERENCES OBSERVATION_CATEGORY ON DELETE CASCADE,
FOREIGN KEY (TYPE_ID) REFERENCES OBSERVATION_TYPE ON DELETE CASCADE
);

CREATE TABLE DISEASE_OBSERVATION_TYPE(
CLASS_ID INTEGER ,
TYPE_ID INTEGER,
--PHYSICIAN_ID VARCHAR2(20) ,
PRIMARY KEY (CLASS_ID,TYPE_ID),
FOREIGN KEY (CLASS_ID) REFERENCES DISEASE_CLASS (CLASS_ID) ON DELETE CASCADE,
FOREIGN KEY (TYPE_ID) REFERENCES OBSERVATION_TYPE (TYPE_ID) ON DELETE CASCADE
--FOREIGN KEY (PHYSICIAN_ID) REFERENCES PHYSICIAN (PHYSICIAN_ID)
);


CREATE TABLE OBSERVATIONS_LOG(
OBSERVATION_ID INTEGER,
PATIENT_ID VARCHAR2(20) NOT NULL,
OBSERVATION_TYPE_ID INTEGER NOT NULL,
VALUE_1 VARCHAR2(100) NOT NULL,
VALUE_2 VARCHAR2(100),
OBSERVATION_DATETIME TIMESTAMP(0) NOT NULL,
RECORDED_DATETIME TIMESTAMP(0) DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (OBSERVATION_ID),
FOREIGN KEY (PATIENT_ID) REFERENCES PATIENT (PATIENT_ID) ON DELETE CASCADE,
FOREIGN KEY (OBSERVATION_TYPE_ID) REFERENCES OBSERVATION_TYPE (TYPE_ID) ON DELETE CASCADE
);

CREATE SEQUENCE OBSERVATIONS_LOG_SEQ;

CREATE OR REPLACE TRIGGER OBSERVATION_ID_TRIG
BEFORE INSERT ON OBSERVATIONS_LOG
FOR EACH ROW
BEGIN
SELECT OBSERVATIONS_LOG_SEQ.nextval INTO :new.OBSERVATION_ID FROM dual;
END;
/

CREATE TABLE MY_ALERTS(
ALERT_ID INTEGER ,
OBSERVATION_ID INTEGER NOT NULL UNIQUE,
ALERT_STATUS CHAR(1),
PRIMARY KEY (ALERT_ID),
FOREIGN KEY (OBSERVATION_ID) REFERENCES OBSERVATIONS_LOG (OBSERVATION_ID) ON DELETE CASCADE
);

CREATE SEQUENCE MY_ALERTS_SEQ;

CREATE OR REPLACE TRIGGER ALERT_ID_TRIG
BEFORE INSERT ON MY_ALERTS
FOR EACH ROW
BEGIN
SELECT MY_ALERTS_SEQ.nextval INTO :new.ALERT_ID FROM dual;
END;
/

CREATE TABLE HEALTH_FRIEND_ALERTS(
SEQ_ID INTEGER,
HEALTH_FRIEND_ID VARCHAR2(20) ,
PATIENT_ID VARCHAR2(20) ,
MESSAGE VARCHAR2(500),
MSG_DATE DATE DEFAULT CURRENT_DATE,
PRIMARY KEY (SEQ_ID) ,
FOREIGN KEY (HEALTH_FRIEND_ID,PATIENT_ID) REFERENCES HEALTH_FRIEND (HEALTH_FRIEND_ID,PATIENT_ID) ON DELETE CASCADE
);

CREATE SEQUENCE HEALTH_FRIEND_ALERTS_SEQ;

CREATE OR REPLACE TRIGGER HEALTH_FRIEND_SEQ_ID_TRIG
BEFORE INSERT ON HEALTH_FRIEND_ALERTS
FOR EACH ROW
BEGIN
SELECT HEALTH_FRIEND_ALERTS_SEQ.nextval INTO :new.SEQ_ID FROM dual;
END;
/

/* Trigger to compare with Threshold and insert row in MY_ALERTS table */
CREATE OR REPLACE TRIGGER CHECK_THRESHOLD 
AFTER INSERT ON OBSERVATIONS_LOG
FOR EACH ROW
DECLARE 
OBS_TYPE VARCHAR2(30);
THRESHOLD VARCHAR2(10);
SYSTOLIC VARCHAR2(10);
DIASTOLIC VARCHAR2(10);
OBS_ID INTEGER := :new.OBSERVATION_ID;

BEGIN

SELECT upper(TYPE_NAME) INTO OBS_TYPE FROM OBSERVATION_TYPE OT WHERE OT.TYPE_ID = :new.OBSERVATION_TYPE_ID;
IF OBS_TYPE='TEMPERATURE' THEN
	SELECT THRESHOLD_VAL INTO THRESHOLD FROM OBSERVATION_TYPE OT WHERE OT.TYPE_ID = :new.OBSERVATION_TYPE_ID;
	IF TO_NUMBER(THRESHOLD) < TO_NUMBER(:new.VALUE_1) THEN
		INSERT INTO MY_ALERTS(OBSERVATION_ID,ALERT_STATUS) VALUES(OBS_ID,'1');
	END IF;
	
ELSIF OBS_TYPE='OXYGEN SATURATION' THEN
	SELECT THRESHOLD_VAL INTO THRESHOLD FROM OBSERVATION_TYPE OT WHERE OT.TYPE_ID = :new.OBSERVATION_TYPE_ID;
	IF TO_NUMBER(THRESHOLD) > TO_NUMBER(:new.VALUE_1) THEN
		INSERT INTO MY_ALERTS(OBSERVATION_ID,ALERT_STATUS) VALUES(OBS_ID,'1');
	END IF;

ELSIF OBS_TYPE='PAIN' THEN
	SELECT THRESHOLD_VAL INTO THRESHOLD FROM OBSERVATION_TYPE OT WHERE OT.TYPE_ID = :new.OBSERVATION_TYPE_ID;
	IF TO_NUMBER(THRESHOLD) < TO_NUMBER(:new.VALUE_1) THEN
		INSERT INTO MY_ALERTS(OBSERVATION_ID,ALERT_STATUS) VALUES(OBS_ID,'1');
	END IF;
	
ELSIF OBS_TYPE='CONTRACTION' THEN
	SELECT THRESHOLD_VAL INTO THRESHOLD FROM OBSERVATION_TYPE OT WHERE OT.TYPE_ID = :new.OBSERVATION_TYPE_ID;
	IF TO_NUMBER(THRESHOLD) < TO_NUMBER(:new.VALUE_1) THEN
		INSERT INTO MY_ALERTS(OBSERVATION_ID,ALERT_STATUS) VALUES(OBS_ID,'1');
	END IF;
	
ELSIF OBS_TYPE='BLOOD PRESSURE' THEN
	
	SELECT SUBSTR(THRESHOLD_VAL,1,INSTR(THRESHOLD_VAL,'/')-1) INTO SYSTOLIC FROM OBSERVATION_TYPE OT WHERE OT.TYPE_ID = :new.OBSERVATION_TYPE_ID;
	SELECT SUBSTR(THRESHOLD_VAL,INSTR(THRESHOLD_VAL,'/')+1) INTO DIASTOLIC FROM OBSERVATION_TYPE OT WHERE OT.TYPE_ID = :new.OBSERVATION_TYPE_ID;
	
	IF (TO_NUMBER(SYSTOLIC) <= TO_NUMBER(SUBSTR(:new.VALUE_1,1,INSTR(:new.VALUE_1,'/')-1))) THEN
		INSERT INTO MY_ALERTS(OBSERVATION_ID,ALERT_STATUS) VALUES(OBS_ID,'1');
	ELSIF (TO_NUMBER(DIASTOLIC) <= TO_NUMBER(SUBSTR(:new.VALUE_1,INSTR(:new.VALUE_1,'/')+1))) THEN
		INSERT INTO MY_ALERTS(OBSERVATION_ID,ALERT_STATUS) VALUES(OBS_ID,'1');
	END IF;
	
END IF;

END;
/



CREATE OR REPLACE PROCEDURE UPDATE_ALERTS
(USR IN VARCHAR2,CNT OUT NUMBER)
IS
BEGIN
UPDATE MY_ALERTS 
SET ALERT_STATUS = '0'
WHERE ALERT_ID IN (
SELECT ALERT_ID FROM MY_ALERTS A, OBSERVATIONS_LOG O
WHERE A.OBSERVATION_ID = O.OBSERVATION_ID 
AND O.PATIENT_ID = USR
AND ALERT_STATUS = '1');
CNT := SQL%ROWCOUNT;
END;
/

COMMIT;