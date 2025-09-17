#!/usr/bin/env python3
"""
Diagnostic script to check why palm reading returns "no data found"
"""
import os
from dotenv import load_dotenv
from supabase import create_client

# Load environment variables
load_dotenv()

def diagnose_palm_reading_setup():
    print("🔍 PALM READING DIAGNOSTIC")
    print("=" * 50)
    
    # Initialize Supabase
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_KEY = os.getenv("SUPABASE_KEY")
    
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("❌ Missing Supabase credentials in .env file")
        return
    
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    print("1. Checking answer_profiles table...")
    try:
        # Get all answer profiles
        response = supabase.table("answer_profiles").select("*").execute()
        profiles = response.data
        
        if not profiles:
            print("❌ No data found in answer_profiles table")
            return
        
        print(f"✅ Found {len(profiles)} profiles")
        
        # Check line_type values
        print("\n2. Checking line_type values...")
        line_types = {}
        for profile in profiles:
            line_type = profile.get('line_type', 'MISSING').strip().lower()
            if line_type not in line_types:
                line_types[line_type] = []
            line_types[line_type].append(profile.get('answer_text', 'NO_TEXT'))
        
        print(f"Found line types: {list(line_types.keys())}")
        
        # Check what the app expects vs what we have
        expected_types = ['life-line', 'head-line', 'heart-line']
        print(f"Expected line types: {expected_types}")
        
        missing_types = []
        for expected in expected_types:
            if expected not in line_types:
                missing_types.append(expected)
        
        if missing_types:
            print(f"❌ Missing line types: {missing_types}")
        else:
            print("✅ All expected line types found")
        
        # Show what we have for each line type
        print("\n3. Detailed breakdown:")
        for line_type, answers in line_types.items():
            print(f"   {line_type}: {len(answers)} profiles")
            for i, answer in enumerate(answers[:3]):  # Show first 3
                print(f"      {i+1}. {answer}")
            if len(answers) > 3:
                print(f"      ... and {len(answers)-3} more")
        
        # Check pkl files
        print("\n4. Checking pkl files...")
        pkl_files = set()
        for profile in profiles:
            pkl_name = profile.get('pkl_name', '')
            if pkl_name:
                pkl_files.add(pkl_name)
        
        print(f"Referenced pkl files: {list(pkl_files)}")
        
        # Try to check storage bucket
        PROFILE_BUCKET = "palm-models"
        try:
            files_in_bucket = supabase.storage.from_(PROFILE_BUCKET).list()
            bucket_files = [f['name'] for f in files_in_bucket if f['name'].endswith('.pkl')]
            print(f"Pkl files in bucket: {bucket_files}")
            
            missing_pkl = pkl_files - set(bucket_files)
            if missing_pkl:
                print(f"❌ Missing pkl files in bucket: {missing_pkl}")
            else:
                print("✅ All pkl files found in bucket")
                
        except Exception as e:
            print(f"⚠️ Could not check storage bucket: {e}")
        
        # Check Admin table for model configs
        print("\n5. Checking Admin table...")
        try:
            admin_response = supabase.table("Admin").select("*").execute()
            admin_data = admin_response.data
            
            if not admin_data:
                print("❌ No model configurations in Admin table")
                return
            
            for config in admin_data:
                model_type = config.get('model_type', 'UNKNOWN')
                is_active = config.get('is_active', False)
                print(f"   {model_type}: {'✅ Active' if is_active else '❌ Inactive'}")
                
        except Exception as e:
            print(f"⚠️ Could not check Admin table: {e}")
            
    except Exception as e:
        print(f"❌ Error accessing database: {e}")

def check_user_profiles_table():
    print("\n" + "=" * 50)
    print("🔍 CHECKING user_profiles TABLE")
    print("=" * 50)
    
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_KEY = os.getenv("SUPABASE_KEY")
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    try:
        # Try to query user_profiles table
        response = supabase.table("user_profiles").select("*").limit(1).execute()
        print("✅ user_profiles table exists")
        print(f"Records found: {len(response.data)}")
    except Exception as e:
        print(f"❌ user_profiles table issue: {e}")
        print("💡 You need to create the user_profiles table:")
        print("""
CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    passcode TEXT UNIQUE NOT NULL,
    image_base64 TEXT,
    last_updated TIMESTAMP DEFAULT NOW()
);
        """)

if __name__ == "__main__":
    diagnose_palm_reading_setup()
    check_user_profiles_table()
    
    