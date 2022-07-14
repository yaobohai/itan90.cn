<script type="text/javascript">
  host = window.location.host
  if (host == "itan90.cn")
    {document.write("<p>当前访问在正式发布环境<p>");}
  else
    {document.write("<p>当前访问在集成测试环境<p>");}
</script>
<p>博客已在腾讯云对象存储中运行<span id="since"></span><span class="my-face">(●'◡'●)ﾉ♥</span></p>
{% if theme.footer.custom_text %}<p>{{ theme.footer.custom_text }}</p>{% endif %}
{% set current = date(Date.now(), "YYYY") %}
<a href="https://beian.miit.gov.cn" target="_blank">豫ICP备19034244号-1</a>
<p>© <span itemprop="copyrightYear">{{ current }}</span> {{ config.title }}.
    由 <a href="https://hexo.io/" target="_blank" class="external" rel="nofollow">Hexo</a> 强力驱动.
    Theme By <a href="https://github.com/DIYgod/hexo-theme-sagiri" target="_blank" class="external" rel="nofollow">Sagiri</a> v{{ theme.version }}.
</p>
<p>Made with <i class="fas fa-heart throb" style="color: #d43f57;"></i> by <span class="author" itemprop="copyrightHolder">{{ theme.footer.copyright || config.author }}</span>. </p>
