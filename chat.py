import google.generativeai as genai
import os

# --- 配置区域 ---
# 在这里填入你刚才从 Google AI Studio 复制的 Key
# 注意：保留引号
MY_API_KEY = "AIzaSyDPbeQAH6gesGTV0W1FNpOfF6Q22j1vyj4" 

if "这里粘贴" in MY_API_KEY:
    print("❌ 错误：请先在代码里填入你的 API Key！")
    exit()

# --- 初始化 ---
genai.configure(api_key=MY_API_KEY)
model = genai.GenerativeModel('gemini-2.5-flash') # 使用免费且快速的模型
chat = model.start_chat(history=[])

print("\n🚀 觉知系统 CLI (v0.1) 已启动")
print("--- 输入 'quit' 退出 ---")

# --- 主循环 ---
while True:
    try:
        user_input = input("\n你: ")
        if user_input.lower() in ['quit', 'exit', 'q']:
            print("👋 再见！")
            break
        
        # 显示等待提示（因为有时候网络会有延迟）
        print("Gemini 思考中...", end="\r")
        
        response = chat.send_message(user_input, stream=True)
        
        print("Gemini: ", end="")
        for chunk in response:
            print(chunk.text, end="", flush=True)
        print() 
        
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")