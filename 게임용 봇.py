import random
import nextcord
from nextcord.ext import commands
import os


access_token - os.environ["bot_token"]
TOKEN = 'access_token'



# 역할의 ID
FIRST_GRADE_ROLE_ID = 1234942571172855890  # 1등급 역할의 ID로 실제 ID를 넣어주세요
SECOND_GRADE_ROLE_ID = 1234942599811432539  # 2등급 역할의 ID로 실제 ID를 넣어주세요
THIRD_GRADE_ROLE_ID = 1234942622016081961  # 3등급 역할의 ID로 실제 ID를 넣어주세요
FOURTH_GRADE_ROLE_ID = 1234942647039299656
FIFTH_GRADE_ROLE_ID = 1234942650906443886
SIXTH_GRADE_ROLE_ID = 1234942700973854750
SEVENTH_GRADE_ROLE_ID = 1234942727259422720
EIGHTH_GRADE_ROLE_ID = 1234942748935847946

# 당첨 확률 (20% = 0.2, 10% = 0.1, 5% = 0.05, 2% = 0.02, 1% = 0.01)
WIN_PROBABILITIES = {
    FIRST_GRADE_ROLE_ID: 0.0008,
    SECOND_GRADE_ROLE_ID: 0.0028,
    THIRD_GRADE_ROLE_ID: 0.0084,
    FOURTH_GRADE_ROLE_ID: 0.01,
    FIFTH_GRADE_ROLE_ID: 0.06,
    SIXTH_GRADE_ROLE_ID: 0.1,
    SEVENTH_GRADE_ROLE_ID: 0.13,
    EIGHTH_GRADE_ROLE_ID: 0.17
}




# 봇 생성
bot = commands.Bot(command_prefix='/', intents=nextcord.Intents.default())

@bot.slash_command(description="ㄱ쩌는 권한을 얻어보세요!")
async def 뽑기(ctx: nextcord.Interaction):
    # 역할마다 당첨 여부 결정
    for role_id, probability in WIN_PROBABILITIES.items():
        if random.random() < probability:
            role = ctx.guild.get_role(role_id)
            if role:
                await ctx.user.add_roles(role)
                await ctx.send(f'{ctx.user.mention}, 축하합니다! {role.name}을(를) 획득하셨습니다.')
            else:
                await ctx.send(f'{role.name} 역할을 찾을 수 없습니다. 관리자에게 문의하세요.')
            break
    else:
        # 어떤 역할도 당첨되지 않았을 경우
        await ctx.send(f'{ctx.user.mention}, 아쉽지만 당첨되지 않았습니다.')


# 봇이 준비되었을 때 실행
@bot.event
async def on_ready():
    print(f'{bot.user.name}이(가) 준비되었습니다.')

# 봇 실행
bot.run(TOKEN)







