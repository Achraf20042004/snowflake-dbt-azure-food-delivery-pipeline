# Import python packages
import streamlit as st
import pandas as pd
import altair as alt
from snowflake.snowpark.context import get_active_session

# ---------------------------------------------------------------
# PAGE CONFIG
# ---------------------------------------------------------------
st.set_page_config(page_title="Revenue Dashboard", page_icon="🍽️", layout="wide")

BRAND = "#ff5200"

# Dark-theme friendly styling (works on Snowflake's dark UI)
st.markdown(
    f"""
    <style>
        div[data-testid="stMetric"] {{
            background: rgba(255,255,255,0.03);
            border: 1px solid rgba(255,255,255,0.08);
            border-left: 3px solid {BRAND};
            padding: 14px 18px;
            border-radius: 10px;
        }}
        div[data-testid="stMetricLabel"] p {{
            font-size: 0.75rem; color: #9aa0aa; font-weight: 600;
            text-transform: uppercase; letter-spacing: .04em;
        }}
        div[data-testid="stMetricValue"] {{ font-weight: 700; font-size: 1.6rem; }}
        h1 {{ color: {BRAND}; }}
        .block-container {{ padding-top: 2rem; }}
    </style>
    """,
    unsafe_allow_html=True,
)

session = get_active_session()

# Altair dark-friendly theme
def style_chart(chart):
    return chart.configure_view(strokeWidth=0).configure_axis(
        labelColor="#c9ccd1", titleColor="#9aa0aa",
        gridColor="rgba(255,255,255,0.06)", domainColor="rgba(255,255,255,0.15)"
    ).configure(background="transparent")

# ---------------------------------------------------------------
# HEADER
# ---------------------------------------------------------------
st.title("🍽️  Revenue Dashboard")
st.caption("Food delivery analytics · powered by Snowflake + dbt")
st.divider()

# ---------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------
def fmt(v): return f"${v:,.0f}"

def fetch_kpi_data():
    return session.sql("""
        SELECT year, total_revenue, total_orders,
               avg_revenue_per_order, avg_revenue_per_item, max_order_value
        FROM sandbox.consumption_sch.vw_yearly_revenue_kpis ORDER BY year;
    """).collect()

def fetch_monthly_kpi_data(year):
    return session.sql(f"""
        SELECT month::number(2) as month, total_revenue::NUMBER(10) AS TOTAL_REVENUE
        FROM sandbox.consumption_sch.vw_monthly_revenue_kpis
        WHERE year = {year} ORDER BY month;
    """).collect()

def fetch_unique_months(year):
    return session.sql(f"""
        SELECT DISTINCT MONTH FROM sandbox.consumption_sch.vw_monthly_revenue_by_restaurant
        WHERE YEAR = {year} ORDER BY MONTH;
    """).collect()

def fetch_top_restaurants(year, month):
    return session.sql(f"""
        SELECT restaurant_name, total_revenue, total_orders,
               avg_revenue_per_order, avg_revenue_per_item, max_order_value
        FROM sandbox.consumption_sch.vw_monthly_revenue_by_restaurant
        WHERE YEAR = {year} AND MONTH = {month}
        ORDER BY total_revenue DESC LIMIT 10;
    """).collect()

def to_pandas(x):
    return pd.DataFrame(x, columns=['Restaurant Name','Total Revenue ($)','Total Orders',
        'Avg Revenue per Order ($)','Avg Revenue per Item ($)','Max Order Value ($)'])

# ---------------------------------------------------------------
# YEARLY DATA
# ---------------------------------------------------------------
df = pd.DataFrame(fetch_kpi_data(),
    columns=['YEAR','TOTAL_REVENUE','TOTAL_ORDERS','AVG_REVENUE_PER_ORDER',
             'AVG_REVENUE_PER_ITEM','MAX_ORDER_VALUE'])

st.subheader("Overall Performance")
o1, o2, o3 = st.columns(3)
o1.metric("Total Revenue (All Years)", fmt(df['TOTAL_REVENUE'].sum()))
o2.metric("Total Orders (All Years)", f"{df['TOTAL_ORDERS'].sum():,}")
o3.metric("Max Order Value", fmt(df['MAX_ORDER_VALUE'].max()))
st.divider()

# ---------------------------------------------------------------
# YEAR SELECTOR + KPIs
# ---------------------------------------------------------------
years = sorted(df["YEAR"].unique())
selected_year = st.selectbox("Select Year", years, index=len(years) - 1)
yd = df[df["YEAR"] == selected_year].iloc[0]
prev = df[df["YEAR"] == selected_year - 1]

def d(col):
    return None if prev.empty else yd[col] - prev.iloc[0][col]

st.subheader(f"KPIs for {selected_year}")
k1, k2, k3 = st.columns(3)
k1.metric("Total Revenue", fmt(yd['TOTAL_REVENUE']),
          delta=fmt(d('TOTAL_REVENUE')) if d('TOTAL_REVENUE') is not None else None)
k1.metric("Total Orders", f"{yd['TOTAL_ORDERS']:,}",
          delta=f"{d('TOTAL_ORDERS'):,.0f}" if d('TOTAL_ORDERS') is not None else None)
k2.metric("Avg Revenue / Order", fmt(yd['AVG_REVENUE_PER_ORDER']),
          delta=fmt(d('AVG_REVENUE_PER_ORDER')) if d('AVG_REVENUE_PER_ORDER') is not None else None)
k2.metric("Avg Revenue / Item", fmt(yd['AVG_REVENUE_PER_ITEM']),
          delta=fmt(d('AVG_REVENUE_PER_ITEM')) if d('AVG_REVENUE_PER_ITEM') is not None else None)
k3.metric("Max Order Value", fmt(yd['MAX_ORDER_VALUE']),
          delta=fmt(d('MAX_ORDER_VALUE')) if d('MAX_ORDER_VALUE') is not None else None)
st.divider()

# ---------------------------------------------------------------
# MONTHLY TREND
# ---------------------------------------------------------------
mdf = pd.DataFrame(fetch_monthly_kpi_data(selected_year),
                   columns=['Month', 'Revenue'])
mmap = {1:'Jan',2:'Feb',3:'Mar',4:'Apr',5:'May',6:'Jun',
        7:'Jul',8:'Aug',9:'Sep',10:'Oct',11:'Nov',12:'Dec'}
mdf['Month'] = pd.Categorical(mdf['Month'].map(mmap),
                              categories=list(mmap.values()), ordered=True)
mdf = mdf.sort_values('Month')

st.subheader(f"{selected_year} — Monthly Revenue Trend")
g1, g2 = st.columns(2)
with g1:
    bar = alt.Chart(mdf).mark_bar(color=BRAND, cornerRadiusTopLeft=4,
        cornerRadiusTopRight=4, size=40).encode(
        x=alt.X('Month', sort=list(mmap.values())),
        y=alt.Y('Revenue', title='Revenue ($)'),
        tooltip=['Month', alt.Tooltip('Revenue', format=',.0f')]
    ).properties(height=360)
    st.altair_chart(style_chart(bar), use_container_width=True)
with g2:
    line = alt.Chart(mdf).mark_line(color=BRAND,
        point=alt.OverlayMarkDef(color=BRAND, size=80), strokeWidth=3).encode(
        x=alt.X('Month', sort=list(mmap.values())),
        y=alt.Y('Revenue', title='Revenue ($)'),
        tooltip=['Month', alt.Tooltip('Revenue', format=',.0f')]
    ).properties(height=360)
    st.altair_chart(style_chart(line), use_container_width=True)
st.divider()

# ---------------------------------------------------------------
# TOP RESTAURANTS
# ---------------------------------------------------------------
st.subheader("Top Restaurants")
months = pd.DataFrame(fetch_unique_months(selected_year), columns=['MONTH'])['MONTH'].unique()
if len(months):
    sm = st.selectbox(f"Select Month ({selected_year})", sorted(months),
                      index=len(sorted(months)) - 1)
    top = fetch_top_restaurants(selected_year, sm)
    if top:
        st.markdown(f"**Top 10 — {mmap[sm]} {selected_year}**")
        st.dataframe(to_pandas(top), hide_index=True, use_container_width=True)
    else:
        st.warning("No data for the selected period.")
else:
    st.info("No monthly restaurant data for this year.")
