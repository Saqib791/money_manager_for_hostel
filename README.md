# 💸 Hostel Money & Tiffin Manager (NEET Aspirant Edition)

Bhai dekh, simple si baat hai. Biology samajh aa rahi hai, Physics dimaag kha rahi hai, aur pocket money mahine ke 15 tareekh tak khatam ho rahi hai. 

Maine ye app isliye banaya kyunki hostel life mein 3 cheezein manage karna sabse mushkil hai:
1. **Backlogs** (Uska toh main kuch nahi kar sakta).
2. **Tiffin Aunty ka Hisab** (Aunty hamesha 30 din ka bill bhejti hai chahe main 4 din ghar gaya tha).
3. **Doston ka Udhar** (Bhai aaj tu dede, kal main paytm kar dunga - aur wo 'kal' kabhi nahi aata).

Selection ho na ho, doston aur tiffin wale ka hisab clear hona chahiye! 

## ✨ Features (Kyun download karein isko?)

🍱 **1. Tiffin Tracker (The Masterpiece)**
- Enter your start date, price per diet, and total days.
- **Calendar System:** Aaj half diet khaya? Tap to mark "Half". Maggi kha li raat ko? Mark "Off". 
- App automatically calculate karega ki aapka tiffin actually kis din khatam hoga. Aunty ko ek extra paisa nahi dene ka!

🤝 **2. Udhar Manager (Khata Book for Friends)**
- Pata karo kisko kitna "Dena hai" (Pay) aur kisse kitna "Lena hai" (Receive).
- Add friends and log transactions like "Udhar Diya", "Udhar Liya", "I Paid", "Got Paid".

💳 **3. Wallet Balance**
- Papa ne mahine ke shuru mein kitne bheje, usme se tiffin ka kitna gaya, aur baaki kitna bacha hai. Live track karo taaki end mein udhar na maangna pade.

📄 **4. "Papa ko Hisab Dena Hai" (PDF Export)**
- Mahine ke end mein jab ghar se call aaye ki "Beta paise kahan gaye?", just click one button.
- App ek professional **PDF Report** generate karega with all your tiffin logs and daily kharcha. WhatsApp it directly to Papa. 

💾 **5. No Internet? No Problem (Local Backup)**
- Pata hai hostel ka Wi-Fi kaisa chalta hai. Ye app pura offline hai. 
- Auto-saves all data to a JSON file in your phone storage. App delete bhi ho gaya toh restore kar lena.

🎨 **6. Dark Mode & Custom Colors**
- Raat ko mock tests dete waqt aankhein waise hi jal rahi hoti hain, isliye Dark mode zaroori tha. You can also change the app theme color.

## 🛠️ Tech Stack (Kya use karke banaya?)
- **Framework:** Flutter (Dart) - *Kyunki ek code likho, dono mobile pe chalao.*
- **State Management:** Provider - *Simple and smooth.*
- **Storage:** SharedPreferences + Local JSON files.
- **PDF Generation:** `pdf` and `path_provider` packages.

## 🚀 How to Run this in your Laptop

Agar tumhara test syllabus complete ho gaya hai aur tum isko run karna chahte ho, toh ye lo steps:

1. Clone this repo:
   ```bash
   git clone [https://github.com/YourUsername/money_manager_for_hostel.git](https://github.com/YourUsername/money_manager_for_hostel.git)
