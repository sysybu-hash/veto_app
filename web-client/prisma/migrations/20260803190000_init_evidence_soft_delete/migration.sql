-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
DO $$ BEGIN
  CREATE TYPE "Role" AS ENUM ('CITIZEN', 'LAWYER', 'ADMIN');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- CreateTable
CREATE TABLE IF NOT EXISTS "User" (
    "id" TEXT NOT NULL,
    "externalId" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT,
    "role" "Role" NOT NULL DEFAULT 'CITIZEN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "Evidence" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "fileUrl" TEXT NOT NULL,
    "fileHash" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "digitalSeal" TEXT,
    "isVerified" BOOLEAN NOT NULL DEFAULT false,
    "sourceEmergencyEventId" TEXT,
    "ownerId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Evidence_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "SosEvent" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "citizenId" TEXT NOT NULL,
    "lat" DOUBLE PRECISION,
    "lng" DOUBLE PRECISION,
    "accuracy" DOUBLE PRECISION,
    "urgency" TEXT NOT NULL DEFAULT 'SOS',
    "stressTest" BOOLEAN NOT NULL DEFAULT false,
    "status" TEXT NOT NULL DEFAULT 'OPEN',
    "claimedById" TEXT,
    "claimedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SosEvent_pkey" PRIMARY KEY ("id")
);

-- Soft-delete column for DBs that already had Evidence via db push
ALTER TABLE "Evidence" ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3);

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "User_externalId_key" ON "User"("externalId");
CREATE UNIQUE INDEX IF NOT EXISTS "User_email_key" ON "User"("email");
CREATE UNIQUE INDEX IF NOT EXISTS "Evidence_ownerId_sourceEmergencyEventId_key" ON "Evidence"("ownerId", "sourceEmergencyEventId");
CREATE INDEX IF NOT EXISTS "Evidence_ownerId_idx" ON "Evidence"("ownerId");
CREATE INDEX IF NOT EXISTS "Evidence_ownerId_deletedAt_idx" ON "Evidence"("ownerId", "deletedAt");
CREATE UNIQUE INDEX IF NOT EXISTS "SosEvent_eventId_key" ON "SosEvent"("eventId");
CREATE INDEX IF NOT EXISTS "SosEvent_status_createdAt_idx" ON "SosEvent"("status", "createdAt");
CREATE INDEX IF NOT EXISTS "SosEvent_citizenId_idx" ON "SosEvent"("citizenId");

-- AddForeignKey (ignore if already present)
DO $$ BEGIN
  ALTER TABLE "Evidence" ADD CONSTRAINT "Evidence_ownerId_fkey"
    FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;
