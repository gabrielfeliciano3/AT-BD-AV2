-- Procedures

-- 1. Procedure para registrar uma nova distribuição de sementes
DELIMITER $$
CREATE PROCEDURE sp_registrar_distribuicao(
    IN p_id_agricultor INT,
    IN p_id_semente INT,
    IN p_quantidade DECIMAL(10,2),
    IN p_data_entrega DATE,
    IN p_responsavel VARCHAR(80)
)
BEGIN
    DECLARE estoque_atual DECIMAL(10,2);
    SELECT quat_disponivel INTO estoque_atual FROM semente WHERE id_semente = p_id_semente;

    IF estoque_atual >= p_quantidade THEN
        INSERT INTO distribuicoes (agricultores_id_agricultores, semente_id_semente, quantidade_entregue, data_entrega, responsavel_entrega, status_sync)
        VALUES (p_id_agricultor, p_id_semente, p_quantidade, p_data_entrega, p_responsavel, 0);

        UPDATE semente SET quat_disponivel = quat_disponivel - p_quantidade WHERE id_semente = p_id_semente;
        SELECT 'Distribuição registrada com sucesso!' AS message;
    ELSE
        SELECT 'Erro: Quantidade solicitada maior que o estoque disponível.' AS message;
    END IF;
END$$
DELIMITER ;

-- 2. Procedure para adicionar um novo registro de cultivo
DELIMITER $$
CREATE PROCEDURE sp_adicionar_cultivo(
    IN p_id_distribuicao INT,
    IN p_foto VARCHAR(255),
    IN p_descricao TEXT,
    IN p_fase ENUM('plantio', 'crescimento', 'floracao', 'colheita')
)
BEGIN
    DECLARE v_id_agricultor INT;
    DECLARE v_id_semente INT;

    SELECT agricultores_id_agricultores, semente_id_semente
    INTO v_id_agricultor, v_id_semente
    FROM distribuicoes WHERE id_distribuicao = p_id_distribuicao;

    INSERT INTO cultivos (id_distribuicao, data_registro, foto_lavoura, descricao, fase_crescimento, distribuicoes_id_distribuicao, distribuicoes_agricultores_id_agricultores, distribuicoes_semente_id_semente)
    VALUES (p_id_distribuicao, CURDATE(), p_foto, p_descricao, p_fase, p_id_distribuicao, v_id_agricultor, v_id_semente);
END$$
DELIMITER ;

-- 3. Procedure para atualizar o status de um cultivo
DELIMITER $$
CREATE PROCEDURE sp_atualizar_fase_cultivo(
    IN p_id_cultivo INT,
    IN p_nova_fase ENUM('plantio', 'crescimento', 'floracao', 'colheita'),
    IN p_nova_descricao TEXT
)
BEGIN
    UPDATE cultivos
    SET fase_crescimento = p_nova_fase, descricao = p_nova_descricao, data_registro = CURDATE()
    WHERE idcultivos = p_id_cultivo;
END$$
DELIMITER ;

-- 4. Procedure para registrar um novo agricultor e um usuário para ele
DELIMITER $$
CREATE PROCEDURE sp_cadastrar_agricultor_completo(
    IN p_nome VARCHAR(45),
    IN p_cpf CHAR(11),
    IN p_endereco VARCHAR(150),
    IN p_telefone VARCHAR(15),
    IN p_email VARCHAR(80),
    IN p_registro_ipa VARCHAR(20),
    IN p_senha VARCHAR(255)
)
BEGIN
    DECLARE novo_id_agricultor INT;

    INSERT INTO agricultores (nome, cpf, endereco, telefone, email, registro_ipa, data_cadastro)
    VALUES (p_nome, p_cpf, p_endereco, p_telefone, p_email, p_registro_ipa, CURDATE());

    SET novo_id_agricultor = LAST_INSERT_ID();

    INSERT INTO usuarios (nome_usuario, email, senha_hash, tipo_usuario, id_en_ti_us, ativo)
    VALUES (p_nome, p_email, p_senha, 'agricultor', novo_id_agricultor, 1);
END$$
DELIMITER ;

-- 5. Procedure para desativar um usuário
DELIMITER $$
CREATE PROCEDURE sp_desativar_usuario(IN p_id_usuario INT)
BEGIN
    UPDATE usuarios SET ativo = 0 WHERE id_usuario = p_id_usuario;
END$$
DELIMITER ;

-- 6. Procedure para registrar uma movimentação na rastreabilidade
DELIMITER $$
CREATE PROCEDURE sp_registrar_movimentacao_semente(
    IN p_id_semente INT,
    IN p_origem VARCHAR(100),
    IN p_destino VARCHAR(45),
    IN p_tipo ENUM('entrada', 'saida', 'retorno'),
    IN p_obs TEXT
)
BEGIN
    INSERT INTO rastreabilidade (semente_id_semente, origem, destino, data_movimentacao, tipo_movimentacao, observacoes)
    VALUES (p_id_semente, p_origem, p_destino, CURDATE(), p_tipo, p_obs);
END$$
DELIMITER ;

-- 7. Procedure para obter relatório de distribuição por agricultor
DELIMITER $$
CREATE PROCEDURE sp_relatorio_agricultor(IN p_id_agricultor INT)
BEGIN
    SELECT
        s.nome_semente,
        d.quantidade_entregue,
        d.data_entrega
    FROM distribuicoes d
    JOIN semente s ON d.semente_id_semente = s.id_semente
    WHERE d.agricultores_id_agricultores = p_id_agricultor;
END$$
DELIMITER ;

-- 8. Procedure para registrar log de sincronização
DELIMITER $$
CREATE PROCEDURE sp_log_sync(
    IN p_id_usuario INT,
    IN p_tabela VARCHAR(45),
    IN p_status VARCHAR(45),
    IN p_detalhes TEXT
)
BEGIN
    INSERT INTO sincronizacoes (usuarios_id_usuario, tabela_afetada, data_sync, status, detalhes)
    VALUES (p_id_usuario, p_tabela, NOW(), p_status, p_detalhes);
END$$
DELIMITER ;

-- 9. Procedure para adicionar nova semente ao estoque
DELIMITER $$
CREATE PROCEDURE sp_adicionar_semente(
    IN p_nome VARCHAR(50),
    IN p_cultura VARCHAR(50),
    IN p_lote VARCHAR(45),
    IN p_validade DATE,
    IN p_origem VARCHAR(100),
    IN p_quantidade DECIMAL(10,2)
)
BEGIN
    INSERT INTO semente (nome_semente, tipo_cultura, lote, data_validade, origem, quat_disponivel)
    VALUES (p_nome, p_cultura, p_lote, p_validade, p_origem, p_quantidade);
END$$
DELIMITER ;

-- 10. Procedure para arquivar registros de histórico antigos (ex: mais de 2 anos)
DELIMITER $$
CREATE PROCEDURE sp_arquivar_historico_antigo()
BEGIN
    -- Aqui poderia ser um INSERT em uma tabela de arquivo `historico_arquivo`
    -- Por simplicidade, vamos apenas deletar
    DELETE FROM historico_registros WHERE data_acao < DATE_SUB(NOW(), INTERVAL 2 YEAR);
END$$
DELIMITER ;


-- Funções

-- 1. Função para obter a quantidade total de sementes distribuídas
DELIMITER $$
CREATE FUNCTION fn_total_distribuido()
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(12,2);
    SELECT SUM(quantidade_entregue) INTO total FROM distribuicoes;
    RETURN total;
END$$
DELIMITER ;

-- 2. Função para verificar o status de um usuário (ativo ou inativo)
DELIMITER $$
CREATE FUNCTION fn_verificar_status_usuario(p_id_usuario INT)
RETURNS VARCHAR(8)
DETERMINISTIC
BEGIN
    DECLARE status_usuario VARCHAR(8);
    SELECT IF(ativo = 1, 'Ativo', 'Inativo') INTO status_usuario FROM usuarios WHERE id_usuario = p_id_usuario;
    RETURN status_usuario;
END$$
DELIMITER ;

-- 3. Função para contar o número de distribuições para um agricultor
DELIMITER $$
CREATE FUNCTION fn_contar_distribuicoes_agricultor(p_id_agricultor INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE num_dist INT;
    SELECT COUNT(*) INTO num_dist FROM distribuicoes WHERE agricultores_id_agricultores = p_id_agricultor;
    RETURN num_dist;
END$$
DELIMITER ;

-- 4. Função para obter o nome da semente a partir do ID da distribuição
DELIMITER $$
CREATE FUNCTION fn_obter_nome_semente_dist(p_id_distribuicao INT)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE nome_s VARCHAR(50);
    SELECT s.nome_semente INTO nome_s
    FROM semente s
    JOIN distribuicoes d ON s.id_semente = d.semente_id_semente
    WHERE d.id_distribuicao = p_id_distribuicao;
    RETURN nome_s;
END$$
DELIMITER ;
