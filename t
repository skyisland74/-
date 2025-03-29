import discord
from discord import app_commands
from discord.ext import commands, tasks
import asyncio
import asyncio
import json
import os
from datetime import timedelta
from discord import app_commands
from discord.ui import Modal, TextInput
from discord import TextStyle
# Server Members Intent 활성화
# 인텐트 설정
intents = discord.Intents.default()
intents.members = True
bot = commands.Bot(command_prefix="!", intents=intents)

# 포인트와 기록을 저장할 딕셔너리
points = {}
point_logs = []

# 특정 역할의 ID (이 ID는 실제 서버의 역할 ID로 교체해야 함)
ADMIN_ROLE_ID = 1340711481443881031  # 디스코드 역할 ID로 교체

# 구매 요청을 받을 사용자 ID (실제 사용자 ID로 교체)
PURCHASE_RECEIVER_ID = 914094812867743844  # 디스코드 사용자 ID로 교체

# 봇 실행 준비
@bot.event
async def on_ready():
    await bot.tree.sync()  # 명령어를 서버에 동기화
    change_status.start()  # 상태 변경 작업 시작
    print(f"Logged in as {bot.user} (ID: {bot.user.id})")
    print("------")

@tasks.loop(seconds=10)  # 10초마다 상태 변경
async def change_status():
    global index
    await bot.change_presence(activity=statuses[index])
    index = (index + 1) % len(statuses)  # 다음 상태로 변경

    
# 상태 목록 (번갈아가면서 표시)
statuses = [
    discord.Game("게임하는 중"),
    discord.Activity(type=discord.ActivityType.listening, name="음악 듣는 중")
]
index = 0  # 상태 인덱스

# 포인트 조정 명령어
@bot.tree.command(name="포인트_조정", description="포인트 정상화")
@app_commands.describe(유저="포인트를 조정할 유저", 포인트="설정할 포인트 값")
@app_commands.checks.has_role(ADMIN_ROLE_ID)
async def adjust_points(interaction: discord.Interaction, 유저: discord.Member, 포인트: int):
    points[유저.id] = 포인트
    point_logs.append(f"{유저.mention}의 포인트가 {포인트}로 설정되었습니다.")

    embed = discord.Embed(
        title="포인트 조정 완료",
        color=discord.Color.blue()
    )
    embed.add_field(name="닉네임", value=유저.mention, inline=False)
    embed.add_field(name="설정된 포인트", value=f"{포인트} 포인트", inline=False)

    await interaction.response.send_message(embed=embed)

@adjust_points.error
async def adjust_points_error(interaction: discord.Interaction, error: app_commands.AppCommandError):
    if isinstance(error, app_commands.MissingRole):
        await interaction.response.send_message("이 명령어를 실행할 권한이 없습니다.", ephemeral=True)

# 포인트 추가 명령어
@bot.tree.command(name="포인트_추가", description="포인트 추가")
@app_commands.describe(유저="포인트를 추가할 유저", 포인트="추가할 포인트 값")
@app_commands.checks.has_role(ADMIN_ROLE_ID)
async def add_points(interaction: discord.Interaction, 유저: discord.Member, 포인트: int):
    if 유저.id in points:
        points[유저.id] += 포인트
    else:
        points[유저.id] = 포인트

    point_logs.append(f"{유저.mention}의 포인트가 {포인트}만큼 추가되었습니다. 현재 포인트: {points[유저.id]}")

    embed = discord.Embed(
        title="포인트 추가 완료",
        color=discord.Color.green()
    )
    embed.add_field(name="닉네임", value=유저.mention, inline=False)
    embed.add_field(name="추가된 포인트", value=f"{포인트} 포인트", inline=False)
    embed.add_field(name="현재 포인트", value=f"{points[유저.id]} 포인트", inline=False)

    await interaction.response.send_message(embed=embed)

@add_points.error
async def add_points_error(interaction: discord.Interaction, error: app_commands.AppCommandError):
    if isinstance(error, app_commands.MissingRole):
        await interaction.response.send_message("이 명령어를 실행할 권한이 없습니다.", ephemeral=True)

# 포인트 감소 명령어
@bot.tree.command(name="포인트_감소", description="포인트 감소")
@app_commands.describe(유저="포인트를 감소시킬 유저", 포인트="감소시킬 포인트 값")
@app_commands.checks.has_role(ADMIN_ROLE_ID)
async def remove_points(interaction: discord.Interaction, 유저: discord.Member, 포인트: int):
    if 유저.id in points:
        points[유저.id] -= 포인트
    else:
        points[유저.id] = 0

    point_logs.append(f"{유저.mention}의 포인트가 {포인트}만큼 감소되었습니다. 현재 포인트: {points[유저.id]}")

    embed = discord.Embed(
        title="포인트 감소 완료",
        color=discord.Color.red()
    )
    embed.add_field(name="닉네임", value=유저.mention, inline=False)
    embed.add_field(name="감소된 포인트", value=f"{포인트} 포인트", inline=False)
    embed.add_field(name="현재 포인트", value=f"{points[유저.id]} 포인트", inline=False)

    await interaction.response.send_message(embed=embed)

# 포인트 확인 명령어
@bot.tree.command(name="포인트_확인", description="포인트 확인가능")
@app_commands.describe(유저="포인트를 확인할 유저")
async def check_points(interaction: discord.Interaction, 유저: discord.Member):
    if 유저.id in points:
        user_points = points[유저.id]
    else:
        user_points = 0
    embed = discord.Embed(title="포인트 확인", color=discord.Color.blue())  # 임베드 색상 변경
    embed.add_field(name="닉네임", value=유저.display_name, inline=False)  # display_name으로 변경
    embed.add_field(name="디스코드 ID", value=유저.id, inline=False)
    embed.add_field(name="현재 포인트", value=user_points, inline=False)
    await interaction.response.send_message(embed=embed, ephemeral=False)

# 포인트 순위 명령어
@bot.tree.command(name="포인트_순위", description="포인트 상위 10명 보여드림")
async def points_ranking(interaction: discord.Interaction):
    sorted_points = sorted(points.items(), key=lambda x: x[1], reverse=True)[:10]
    embed = discord.Embed(title="포인트 순위", color=discord.Color.gold())  # 임베드 색상 변경
    for i, (user_id, point) in enumerate(sorted_points, 1):
        member = interaction.guild.get_member(user_id)
        if member:
            embed.add_field(name=f"{i}위: {member.display_name}", value=f"{point} 포인트", inline=False)
        else:
            embed.add_field(name=f"{i}위: Unknown User (ID: {user_id})", value=f"{point} 포인트", inline=False)
    await interaction.response.send_message(embed=embed)


# 구매 명령어
@bot.tree.command(name="구매", description="상품을 구매합니다.")
@app_commands.describe(상품="구매할 상품 이름")
async def purchase(interaction: discord.Interaction, 상품: str):
    await interaction.response.send_message(f"구매 요청이 정상적으로 전달됨. 담당자가 확인할때까지 기다려주세요.", ephemeral=True)
    
    # 구매 요청을 특정 인원에게 DM으로 전송
    receiver = await bot.fetch_user(PURCHASE_RECEIVER_ID)
    embed = discord.Embed(title="구매 요청", color=discord.Color.purple())
    embed.add_field(name="구매자", value=interaction.user.mention, inline=False)
    embed.add_field(name="상품", value=상품, inline=False)
    await receiver.send(embed=embed)

# 특정 역할 ID (이 ID는 실제 서버의 역할 ID로 교체해야 함)
AUTHORIZED_ROLE_ID = 1321051972857499734  # 특정 권한이 있는 역할 ID로 교체

# 모든 유저의 포인트 확인 명령어
@bot.tree.command(name="모든포인트확인", description="현재 포인트가 있는 모든 유저의 포인트를 확인합니다.")
@app_commands.checks.has_role(AUTHORIZED_ROLE_ID)  # 특정 역할을 가진 사용자만 사용 가능
async def all_points(interaction: discord.Interaction):
    if not points:
        await interaction.response.send_message("현재 포인트가 기록된 유저가 없습니다.", ephemeral=True)
        return
    
    # 포인트가 있는 모든 유저의 포인트를 정렬하여 출력
    sorted_points = sorted(points.items(), key=lambda x: x[1], reverse=True)
    embed = discord.Embed(title="모든 유저의 포인트", color=discord.Color.blue())  # 임베드 색상 변경
    
    for i, (user_id, point) in enumerate(sorted_points, 1):
        member = interaction.guild.get_member(user_id)
        if member:
            embed.add_field(name=f"{i}. {member.display_name}", value=f"{point} 포인트", inline=False)
        else:
            embed.add_field(name=f"{i}. Unknown User (ID: {user_id})", value=f"{point} 포인트", inline=False)

    await interaction.response.send_message(embed=embed, ephemeral=True)

@all_points.error
async def all_points_error(interaction: discord.Interaction, error: app_commands.AppCommandError):
    if isinstance(error, app_commands.MissingRole):
        await interaction.response.send_message("이 명령어를 실행할 권한이 없습니다.", ephemeral=True)

# 문의 명령어
@bot.tree.command(name="문의", description="장난식으로 작성시 밴")
@app_commands.describe(문의="문의할 내용을 입력하세요.")
async def inquiry(interaction: discord.Interaction, 문의: str):
    # 유저에게 확인 메시지 전송
    await interaction.response.send_message("문의가 접수됨. 담당자 확인후 연락드리겠습니다.", ephemeral=True)
    
    # 특정 사용자 ID에 대해 문의 내용 전송
    RECEIVER_ID = 914094812867743844  # 문의를 받을 사용자 ID로 변경
    receiver = await bot.fetch_user(RECEIVER_ID)  # 사용자 ID를 통해 유저 객체 가져오기
    embed = discord.Embed(title="문의 접수", color=discord.Color.blue())
    embed.add_field(name="대상자", value=interaction.user.mention, inline=False)
    embed.add_field(name="대상자 ID", value=interaction.user.id, inline=False)
    embed.add_field(name="문의 내용", value=문의, inline=False)
    
    # 특정 사용자에게 DM 전송
    await receiver.send(embed=embed)
# 🕒 /타임아웃 명령어
@bot.tree.command(name="타임아웃", description="탐아나 드셔")
@app_commands.describe(
    user="유저",  # ✅ "유저" -> 한글 설명
    time="지속 시간",  # ✅ "시간" -> 한글 설명
    reason="사유 (선택)"  # ✅ "사유" -> 한글 설명
)
async def timeout(interaction: discord.Interaction, user: discord.Member, time: str, reason: str = "사유 없음"):
    # 권한 체크
    if not interaction.user.guild_permissions.moderate_members:
        embed = discord.Embed(title="뭐야, 권한도 딸리네?", description="권한도 없으면서 뭘써", color=discord.Color.red())
        return await interaction.response.send_message(embed=embed, ephemeral=True)

    # 시간 변환 (s, m, h 지원)
    time_unit = {"s": 1, "m": 60, "h": 3600}
    unit = time[-1]
    if unit not in time_unit or not time[:-1].isdigit():
        embed = discord.Embed(title="뭐야, 양식도 틀려?", description="`10s`, `5m`, `1h`", color=discord.Color.orange())
        return await interaction.response.send_message(embed=embed, ephemeral=True)

    duration = int(time[:-1]) * time_unit[unit]

    # 유저 타임아웃 적용
    try:
        await user.timeout(discord.utils.utcnow() + timedelta(seconds=duration), reason=reason)

        embed = discord.Embed(
            title="타임아웃 완료",
            description=f"**{user.mention} 님이 {time} 동안 타임아웃되었습니다.**",
            color=discord.Color.blue()
        )
        embed.add_field(name="대상자", value=user.mention, inline=True)
        embed.add_field(name="시간", value=time, inline=True)
        embed.add_field(name="사유", value=reason, inline=False)
        embed.set_thumbnail(url=user.avatar.url if user.avatar else user.default_avatar.url)
        embed.set_footer(text=f"처리자: {interaction.user}", icon_url=interaction.user.avatar.url if interaction.user.avatar else interaction.user.default_avatar.url)

        await interaction.response.send_message(embed=embed)

    except Exception as e:
        embed = discord.Embed(title="❌ 오류 발생", description=f"```\n{e}\n```", color=discord.Color.red())
        await interaction.response.send_message(embed=embed, ephemeral=True)

        
# 🔹 모달 UI 정의
class DMModal(Modal, title="DM 보내기"):
    def __init__(self, user: discord.User):
        super().__init__()
        self.user = user

        # 🔹 제목 입력
        self.title_input = TextInput(
            label="제목",
            placeholder="제목을 입력하세요",
            max_length=100,
            required=True
        )
        self.add_item(self.title_input)

        # 🔹 내용 입력
        self.content_input = TextInput(
            label="내용",
            placeholder="보낼 메시지를 입력하세요",
            style=TextStyle.paragraph,
            required=True
        )
        self.add_item(self.content_input)

    async def on_submit(self, interaction: discord.Interaction):
        title = self.title_input.value
        content = self.content_input.value

        embed = discord.Embed(
            title=title,
            description=content,
            color=discord.Color.blue()
        )
        embed.set_footer(text=f"보낸 사람: {interaction.user}", icon_url=interaction.user.display_avatar.url)

        try:
            await self.user.send(embed=embed)
            await interaction.response.send_message(f"✅ {self.user.mention}에게 전달완료", ephemeral=True)
        
        except discord.Forbidden:
            await interaction.response.send_message(f"❌ {self.user.mention}에게 DM을 보낼 수 없습니다.\n**이유:** 봇과 같은 서버에 없거나, DM 설정이 비활성화됨.", ephemeral=True)

# 🔹 슬래시 명령어 정의
@bot.tree.command(name="dm_전송", description="dm보내기")
@app_commands.describe(user="DM을 받을 유저")
async def send_dm(interaction: discord.Interaction, user: discord.User):
    modal = DMModal(user=user)
    await interaction.response.send_modal(modal)
